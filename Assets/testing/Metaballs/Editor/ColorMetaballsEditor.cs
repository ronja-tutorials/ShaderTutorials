using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(ColorMetaballs))]
public class ColorMetaballsEditor : Editor {
	ColorMetaballs metaballTarget;
	int lastEdited = -1;

	public override void OnInspectorGUI()
    {
		DrawDefaultInspector();

       	metaballTarget = target as ColorMetaballs;
		if(!metaballTarget)
			return;
		
		if(GUILayout.Button("Add point"))
        {
			Undo.RecordObject(target, "Add point");

			System.Array.Resize(ref metaballTarget.positions, metaballTarget.positions.Length + 1);
			System.Array.Resize(ref metaballTarget.colors, metaballTarget.colors.Length + 1);
			System.Array.Resize(ref metaballTarget.properties, metaballTarget.properties.Length + 1);

			metaballTarget.positions[metaballTarget.positions.Length - 1] = new Vector4(UnityEngine.Random.Range(-1f, 1f), UnityEngine.Random.Range(-1f, 1f), 0, 1);
			metaballTarget.colors[metaballTarget.colors.Length - 1] = Color.HSVToRGB(UnityEngine.Random.value, 1, 1);
			metaballTarget.properties[metaballTarget.colors.Length - 1] = new Vector4(1, 0, 0, 0);

            metaballTarget.UpdateMaterial();
        }

		if(GUILayout.Button("randomize colors"))
        {
			Undo.RecordObject(target, "randomize colors");
			for(int i=0; i < metaballTarget.colors.Length; i++){
				float h, s, v;
				Color.RGBToHSV(metaballTarget.colors[i], out h, out s, out v);
				//h;
				if(s > 0)
					s += UnityEngine.Random.Range(-0.05f, 0.05f);
				v += UnityEngine.Random.Range(-0.05f, 0.05f);
				metaballTarget.colors[i] = Color.HSVToRGB(h, s, v);
			}
		}

		if(lastEdited >= 0){
			GUILayout.Label("last edited: " + lastEdited);
			if(GUILayout.Button("delete point number " + lastEdited))
			{
				Undo.RecordObject(target, "delete metaball " + lastEdited);
				metaballTarget.positions = metaballTarget.positions.RemoveAt(lastEdited);
				metaballTarget.colors = metaballTarget.colors.RemoveAt(lastEdited);
				metaballTarget.properties = metaballTarget.properties.RemoveAt(lastEdited);
				metaballTarget.UpdateMaterial();
			}

			EditorGUI.BeginChangeCheck();
			Vector4 pos = EditorGUILayout.Vector4Field("Position " + lastEdited, metaballTarget.positions[lastEdited]);
			Color col = EditorGUILayout.ColorField("Color " + lastEdited, metaballTarget.colors[lastEdited]);
			Vector4 props = EditorGUILayout.Vector4Field("Size, Hole - " + lastEdited, metaballTarget.properties[lastEdited]);
			if (EditorGUI.EndChangeCheck())
			{
				Undo.RecordObject(target, "change point " + lastEdited);
				metaballTarget.positions[lastEdited] = pos;
				metaballTarget.colors[lastEdited] = col;
				metaballTarget.properties[lastEdited] = props;
			}
		}

		metaballTarget.UpdateMaterial();
    }

	public void OnSceneGUI(){
		metaballTarget = target as ColorMetaballs;
		if(!metaballTarget)
			return;
		
		for(int i=0; i < metaballTarget.positions.Length; i++){
			EditorGUI.BeginChangeCheck();
			
			Handles.color = Color.gray;
			Vector3 pos = Handles.FreeMoveHandle(metaballTarget.positions[i], Quaternion.identity, 0.03f, Vector3.zero, Handles.DotHandleCap);
			if (EditorGUI.EndChangeCheck())
			{
				Undo.RecordObject(target, "Move point " + i);
				metaballTarget.positions[i] = new Vector4(pos.x, pos.y, pos.z, metaballTarget.positions[i].w);
				metaballTarget.UpdateMaterial();
				lastEdited = i;
			}
		}
	}
}
