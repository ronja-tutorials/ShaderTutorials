using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;
using Object = UnityEngine.Object;

public class MaterialGradientDrawer : MaterialPropertyDrawer {
	private static Dictionary<(int, string), Gradient> knownGradients = new Dictionary<(int, string), Gradient>();

	private int resolution;

	public MaterialGradientDrawer() {
		resolution = 256;
	}

	public MaterialGradientDrawer(float res) {
		resolution = (int)res;
	}

	private static bool IsPropertyTypeSuitable(MaterialProperty prop) {
		return prop.type == MaterialProperty.PropType.Texture;
	}
	
	public string TextureName(MaterialProperty prop) => $"{prop.name}Tex";

	public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor) {
		if (!IsPropertyTypeSuitable(prop)) {
			EditorGUI.HelpBox(position, $"[Gradient] used on non-texture property \"{prop.name}\"", MessageType.Error);
			return;
		}

		if (!AssetDatabase.Contains(prop.targets.FirstOrDefault())) {
			EditorGUI.HelpBox(position, $"Material \"{prop.targets.FirstOrDefault()?.name}\" is not an Asset!",
				MessageType.Error);
			return;
		}

		var textureName = TextureName(prop);

		Gradient currentGradient = null;
		if (prop.targets.Length == 1) {
			var target = (Material) prop.targets[0];
			var path = AssetDatabase.GetAssetPath(target);
			if (!knownGradients.TryGetValue((target.GetInstanceID(), textureName), out currentGradient)) {
				var textureAsset = GetTextureAsset(path, textureName);
				currentGradient = textureAsset != null
					? Decode(prop, textureAsset.name)
					: new Gradient {
						colorKeys = new[] {new GradientColorKey(Color.blue, 0), new GradientColorKey(Color.red, 1)},
					};
				knownGradients[(target.GetInstanceID(), textureName)] = currentGradient;
			}

			EditorGUI.showMixedValue = false;
		} else {
			EditorGUI.showMixedValue = true;
		}

		using (var changeScope = new EditorGUI.ChangeCheckScope()) {
			currentGradient = EditorGUILayout.GradientField(label, currentGradient);

			if (changeScope.changed) {
				string encodedGradient = Encode(currentGradient);
				string fullAssetName = textureName + encodedGradient;
				foreach (Object target in prop.targets) {
					if (!AssetDatabase.Contains(target)) //failsafe for non-asset materials - should never trigger
						continue;

					var path = AssetDatabase.GetAssetPath(target);
					var textureAsset = GetTextureAsset(path, textureName);
					if (textureAsset == null) {
						textureAsset = new Texture2D(resolution, 1, TextureFormat.ARGB32, false);
						textureAsset.wrapMode = TextureWrapMode.Clamp;
						textureAsset.name = textureName;
						AssetDatabase.AddObjectToAsset(textureAsset, path);
						AssetDatabase.ImportAsset(path);
					}

					if (textureAsset.width != resolution) {
						textureAsset.Resize(resolution, 1);
					}

					textureAsset.name = fullAssetName;
					BakeGradient(currentGradient, textureAsset);
					EditorUtility.SetDirty(textureAsset);
					//we need ImportAsset for changes to show up, but also it costs 100ms per tick and I dont wanna pay that ^^
					//AssetDatabase.ImportAsset(path);

					var material = (Material) target;
					material.SetTexture(prop.name, textureAsset);
				}
			}
		}

		EditorGUI.showMixedValue = false;
	}

	private string Encode(Gradient gradient) {
		return JsonUtility.ToJson(new GradientRepresentation(gradient));
	}

	private Gradient Decode(MaterialProperty prop, string name) {
		string json = name.Substring(TextureName(prop).Length);
		return JsonUtility.FromJson<GradientRepresentation>(json).ToGradient();
	}

	private Texture2D GetTextureAsset(string path, string name) {
		return AssetDatabase.LoadAllAssetsAtPath(path).FirstOrDefault(asset => asset.name.StartsWith(name)) as Texture2D;
	}

	private void BakeGradient(Gradient gradient, Texture2D texture) {
		for (int x = 0; x < texture.width; x++) {
			var color = gradient.Evaluate((float) x / (texture.width - 1));
			for (int y = 0; y < texture.height; y++) {
				texture.SetPixel(x, y, color);
			}
		}

		texture.Apply();
	}

	public override void Apply(MaterialProperty prop) {
		var textureName = TextureName(prop);
		foreach (Object target in prop.targets) {
			if (!AssetDatabase.Contains(target)) //failsafe for non-asset materials - should never trigger
				continue;

			var path = AssetDatabase.GetAssetPath(target);
			Gradient currentGradient = null;
			var textureAsset = GetTextureAsset(path, textureName);
			if (!knownGradients.TryGetValue((target.GetInstanceID(), textureName), out currentGradient)) {
				currentGradient = textureAsset != null
					? Decode(prop, textureAsset.name)
					: new Gradient {
						colorKeys = new[] {new GradientColorKey(Color.blue, 0), new GradientColorKey(Color.red, 1)},
					};
				knownGradients[(target.GetInstanceID(), textureName)] = currentGradient;
			}

			if (textureAsset == null) {
				textureAsset = new Texture2D(resolution, 1, TextureFormat.ARGB32, false);
				textureAsset.wrapMode = TextureWrapMode.Clamp;
				textureAsset.name = textureName;
				AssetDatabase.AddObjectToAsset(textureAsset, path);
				AssetDatabase.ImportAsset(path);
			}

			if (textureAsset.width != resolution) {
				textureAsset.Resize(resolution, 1);
			}

			string fullAssetName = textureName + Encode(currentGradient);

			textureAsset.name = fullAssetName;
			BakeGradient(currentGradient, textureAsset);
			EditorUtility.SetDirty(textureAsset);
			AssetDatabase.ImportAsset(path);

			var material = (Material) target;
			material.SetTexture(prop.name, textureAsset);
		}
	}

	[MenuItem("Assets/Remove All Subassets")]
	static void RemoveAllSubassets() {
		foreach (Object asset in Selection.GetFiltered<Object>(SelectionMode.Assets)) {
			var path = AssetDatabase.GetAssetPath(asset);
			foreach (Object subAsset in AssetDatabase.LoadAllAssetRepresentationsAtPath(path)) {
				Object.DestroyImmediate(subAsset, true);
			}
			AssetDatabase.ImportAsset(path);
		}
	}

	class GradientRepresentation {
		public GradientMode mode;
		public ColorKey[] colorKeys;
		public AlphaKey[] alphaKeys;

		public GradientRepresentation() { }

		public GradientRepresentation(Gradient source) {
			FromGradient(source);
		}

		public void FromGradient(Gradient source) {
			mode = source.mode;
			colorKeys = source.colorKeys.Select(key => new ColorKey(key)).ToArray();
			alphaKeys = source.alphaKeys.Select(key => new AlphaKey(key)).ToArray();
		}

		public void ToGradient(Gradient gradient) {
			gradient.mode = mode;
			gradient.colorKeys = colorKeys.Select(key => key.ToGradientKey()).ToArray();
			gradient.alphaKeys = alphaKeys.Select(key => key.ToGradientKey()).ToArray();
		}

		public Gradient ToGradient() {
			var gradient = new Gradient();
			ToGradient(gradient);
			return gradient;
		}

		[Serializable]
		public struct ColorKey {
			public Color color;
			public float time;

			public ColorKey(GradientColorKey source) {
				color = default;
				time = default;
				FromGradientKey(source);
			}

			public void FromGradientKey(GradientColorKey source) {
				color = source.color;
				time = source.time;
			}

			public GradientColorKey ToGradientKey() {
				GradientColorKey key;
				key.color = color;
				key.time = time;
				return key;
			}
		}

		[Serializable]
		public struct AlphaKey {
			public float alpha;
			public float time;

			public AlphaKey(GradientAlphaKey source) {
				alpha = default;
				time = default;
				FromGradientKey(source);
			}

			public void FromGradientKey(GradientAlphaKey source) {
				alpha = source.alpha;
				time = source.time;
			}

			public GradientAlphaKey ToGradientKey() {
				GradientAlphaKey key;
				key.alpha = alpha;
				key.time = time;
				return key;
			}
		}
	}
}