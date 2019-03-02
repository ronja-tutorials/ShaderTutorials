/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 * Latest Update: SDF Toolkit beta 1.1
 * First Release: SDF Toolkit beta 1.1
 */

using UnityEngine;
using UnityEngine.UI;
using System;

namespace CatlikeCoding.SDFToolkit {

	/// <summary>
	/// Component that links a UI graphic to the material asset it uses.
	/// </summary>
	/// <description>
	/// When a graphic is inside a clip area, it ends up batched and working with a copy of its material,
	/// instead of the actual material asset. This currently leads to two problems.
	/// 
	/// First, the UI graphic won't update automatically when you adjust its material in the editor, which is annoying.
	/// 
	/// Second, shader keywords are not copied, which means that materials that rely on keywords are unusable.
	/// 
	/// This component solves both problems. You have to add it to each affected graphic object and manually
	/// connect the right material.
	/// </description>
	[ExecuteInEditMode, System.Obsolete("UIMaterialLink is no longer needed to make keyword materials work at run time. It will be removed in a future release.")]
	public class UIMaterialLink : MonoBehaviour {

		/// <summary>
		/// Get or set the source material. Only really useful for editor scripts.
		/// </summary>
		public Material SourceMaterial {
			get {
				return sourceMaterial;
			}
			set {
				if (value != sourceMaterial) {
					sourceMaterial = value;
					shaderKeywords = null;
				}
			}
		}

		/// <summary>
		/// Material used to render the graphic. You have to connect this manually.
		/// </summary>
		[SerializeField]
		private Material sourceMaterial;

		[NonSerialized]
		private string[] shaderKeywords;
		
		/// <summary>
		/// Modify a graphic's material. This method is invoked by the UI system.
		/// </summary>
		/// <param name="baseMaterial">Base material.</param>
		public Material GetModifiedMaterial (Material baseMaterial) {
			if (shaderKeywords == null) {
				if (sourceMaterial == null) {
					Debug.LogWarning("UIMaterialLink needs a material reference!", this);
				}
				else {
					shaderKeywords = sourceMaterial.shaderKeywords;
				}
			}
			baseMaterial.shaderKeywords = shaderKeywords;
			return baseMaterial;
		}

	#if UNITY_EDITOR
		private void Update () {
			if (UnityEditor.Selection.activeObject == sourceMaterial) {
				// With the source material selected, update the graphic's material whenever something changes.
				Graphic g = GetComponent<Graphic>();
				if (g != null) {
					shaderKeywords = null;
					g.SetMaterialDirty();
				}
			}
		}
	#endif
	}
}