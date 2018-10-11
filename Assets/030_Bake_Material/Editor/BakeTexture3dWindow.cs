using UnityEngine;
using UnityEditor;
using System.IO;
using System;

public class BakeTexture3dWindow : EditorWindow {

    Material ImageMaterial;
    string FilePath = "Assets/MaterialImage.asset";
    Vector3Int Resolution;

    bool hasMaterial;
    bool hasResolution;
    bool hasFilePath;

    [MenuItem ("Tools/Bake material to 3d texture")]
    static void OpenWindow() {
        //create window
        BakeTexture3dWindow window = EditorWindow.GetWindow<BakeTexture3dWindow>();
        window.Show();

        window.CheckInput();
    }

    void OnGUI(){
        EditorGUILayout.HelpBox("Set the material you want to bake as well as the size "+
                "and location of the texture you want to bake to, then press the \"Bake\" button.", MessageType.None);

        using(var check = new EditorGUI.ChangeCheckScope()){
            ImageMaterial = (Material)EditorGUILayout.ObjectField("Material", ImageMaterial, typeof(Material), false);
            Resolution = EditorGUILayout.Vector3IntField("Image Resolution", Resolution);
            FilePath = FileField(FilePath);

            if(check.changed){
                CheckInput();
            }
        }

        GUI.enabled = hasMaterial && hasResolution && hasFilePath;
        if(GUILayout.Button("Bake")){
            BakeTexture();
        }
        GUI.enabled = true;

        //tell the user what inputs are missing
        if(!hasMaterial){
            EditorGUILayout.HelpBox("You're still missing a material to bake.", MessageType.Warning);
        }
        if(!hasResolution){
            EditorGUILayout.HelpBox("Please set a size bigger than zero.", MessageType.Warning);
        }
        if(!hasFilePath){
            EditorGUILayout.HelpBox("No file to save the image to given.", MessageType.Warning);
        }
    }

    void CheckInput(){
        //check which values are entered already
        hasMaterial = ImageMaterial != null;
        hasResolution = Resolution.x > 0 && Resolution.y > 0 && Resolution.z > 0;
        hasFilePath = false;
        try{
            string ext = Path.GetExtension(FilePath);
            hasFilePath = ext.Equals(".asset");
        } catch(ArgumentException){}
    }

    string FileField(string path){
        //allow the user to enter output file both as text or via file browser
        EditorGUILayout.LabelField("Image Path");
        using(new GUILayout.HorizontalScope()){
            path = EditorGUILayout.TextField(path);
            if(GUILayout.Button("choose")){
                //set default values for directory, then try to override them with values of existing path
                string directory = "Assets";
                string fileName = "MaterialImage.asset";
                try{
                    directory = Path.GetDirectoryName(path);
                    fileName = Path.GetFileName(path);
                } catch(ArgumentException){}
                string chosenFile = EditorUtility.SaveFilePanelInProject("Choose image file", fileName, 
                        "asset", "Please enter a file name to save the image to", directory);
                if(!string.IsNullOrEmpty(chosenFile)){
                    path = chosenFile;
                }
                //repaint editor because the file changed and we can't set it in the textfield retroactively
                Repaint();
            }
        }
        return path;
    }

    void BakeTexture(){
        //get rendertexture to render layers to and texture3d to save values to as well as 2d texture for transferring data
        RenderTexture renderTexture = RenderTexture.GetTemporary(Resolution.x, Resolution.y);
        Texture3D volumeTexture = new Texture3D(Resolution.x, Resolution.y, Resolution.z, TextureFormat.ARGB32, false);
        Texture2D tempTexture = new Texture2D(Resolution.x, Resolution.y);

        //prepare for loop
        RenderTexture.active = renderTexture;
        int voxelAmount = Resolution.x * Resolution.y * Resolution.z;
        int slicePixelAmount = Resolution.x * Resolution.y;
        Color32[] colors = new Color32[voxelAmount];

        //loop through slices
        for(int slice=0; slice<Resolution.z; slice++){
            //set z coodinate in shader
            float height = (slice + 0.5f) / Resolution.z;
            ImageMaterial.SetFloat("_Height", height);

            //get shader result
            Graphics.Blit(null, renderTexture, ImageMaterial);
            tempTexture.ReadPixels(new Rect(0, 0, Resolution.x, Resolution.y), 0, 0);
            Color32[] sliceColors = tempTexture.GetPixels32();

            //copy slice to data for 3d texture
            int sliceBaseIndex = slice * slicePixelAmount;
            for(int pixel=0; pixel<slicePixelAmount; pixel++){
                colors[sliceBaseIndex + pixel] = sliceColors[pixel];
            }
        }

        //apply and save 3d texture
        volumeTexture.SetPixels32(colors);
        AssetDatabase.CreateAsset(volumeTexture, FilePath);

        //clean up variables
        RenderTexture.active = null;
        RenderTexture.ReleaseTemporary(renderTexture);
        DestroyImmediate(volumeTexture);
        DestroyImmediate(tempTexture);
    }
}