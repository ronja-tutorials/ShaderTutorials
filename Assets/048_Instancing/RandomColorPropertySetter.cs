using UnityEngine;

public class RandomColorPropertySetter : MonoBehaviour
{
    //The material property block we pass to the GPU
    MaterialPropertyBlock propertyBlock;

    // OnValidate is called in the editor after the component is edited
    void OnValidate()
    {
        //create propertyblock only if none exists
        if (propertyBlock == null)
            propertyBlock = new MaterialPropertyBlock();
        //Get a renderer component either of the own gameobject or of a child
        Renderer renderer = GetComponentInChildren<Renderer>();
        //set the color property
        propertyBlock.SetColor("_Color", GetRandomColor());
        //apply propertyBlock to renderer
        renderer.SetPropertyBlock(propertyBlock);
    }

    static Color GetRandomColor()
    {
        return Color.HSVToRGB(Random.value, 1, .9f);
    }
}