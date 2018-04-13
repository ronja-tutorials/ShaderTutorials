using UnityEngine;
using UnityEditor;
using FontAtlasGen.Util;
using System.Collections.Generic;

namespace FontAtlasGen.FontAtlasGenEditor
{
    /// <summary>
    /// EditorWindow for exporting a Font Atlas from a set of characters.
    /// </summary>
    public class FontAtlasGeneratorEditorWindow : EditorWindow
    {
        const string CODE_PAGE_437_STR_ =
@" ☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼ !""#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~⌂ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀αßΓπΣσµτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■ ";

        [SerializeField]
        Font font_;

        [SerializeField]
        Material mat_;
        Material Material_
        {
            get
            {
                if (mat_ == null)
                {
                    mat_ = new Material(Shader.Find("GUI/Text Shader"));
                    mat_.hideFlags = HideFlags.HideAndDontSave;
                }
                return mat_;
            }
        }

        [SerializeField]
        Material fallbackMat_;
        Material FallbackMat_
        {
            get
            {
                if (fallbackMat_ == null)
                {
                    fallbackMat_ = new Material(Shader.Find("GUI/Text Shader"));
                    fallbackMat_.hideFlags = HideFlags.HideAndDontSave;
                }
                return fallbackMat_;
            }
        }

        Texture2D grabTexture_ = null;
        RenderTexture renderTexture_ = null;

        [SerializeField]
        int fontSize_ = 8;

        [SerializeField]
        int lastFontSize_;

        [SerializeField]
        int fallbackFontSize_ = 8;

        [SerializeField]
        int lastFallbackFontSize_ = 0;

        [SerializeField]
        string glyphString_ = "a";

        [SerializeField]
        string fallbackString_ = "";

        [SerializeField]
        string customString_ = "Custom";

        enum SelectedGlyphs
        {
            Custom = 0,
            Code_Page_437 = 1,
        };

        [SerializeField]
        SelectedGlyphs selectedGlyphs_ = SelectedGlyphs.Code_Page_437;

        [SerializeField]
        IntVector2 glyphDimensions_ = new IntVector2(8, 8);
        /// <summary>
        /// Vertical offset applied to each glyph on the tilesheet. The proper value seems
        /// to vary from Font to Font, and as far as I can see the only way to get the right
        /// value is to tweak it manually.
        /// </summary>
        [SerializeField]
        int verticalOffset_ = 1;

        [SerializeField]
        int fallbackVerticalOffset_ = 1;

        /// <summary>
        /// The maximum number of glyphs per row.
        /// </summary>
        [SerializeField]
        int columnCount_ = 16;

        /// <summary>
        /// Whether or not to draw a cell grid over the preview image. Can help when sizing/positioning glyphs.
        /// </summary>
        [SerializeField]
        bool drawPreviewGrid_ = false;

        [SerializeField]
        Color previewGridColor_ = new Color(50f / 255f, 205f / 255f, 150f / 255f, .35f);

        [SerializeField]
        Color backgroundColor_ = Color.black;

        [SerializeField]
        Color textColor_ = Color.white;
       


        enum UnsupportedGlyphHandling
        {
            // Specify a fallback font to pull glyphs from if the original font doesn't support it
            Fallback,
            // Replace any unsupported characters with an empty glyph
            Empty,
            // Remove unsupported characters from the input string
            Remove
        }

        [SerializeField]
        UnsupportedGlyphHandling unsupportedGlyphHandling_ = UnsupportedGlyphHandling.Empty;

        /// <summary>
        /// Fallback font for <seealso cref="UnsupportedGlyphHandling.Fallback"/> with Unicode fonts.
        /// </summary>
        [SerializeField]
        Font fallbackFont_ = null;

        FontAtlasMesh mesh_ = new FontAtlasMesh();

        FontAtlasMesh fallbackMesh_ = new FontAtlasMesh();

        [MenuItem("Window/FontAtlasGenerator", false, 500)]
        static void MakeWindow()
        {
            GetWindow<FontAtlasGeneratorEditorWindow>().Show();
        }

        enum ToolbarItem
        {
            Font = 0,
            Glyphs = 1,
            Atlas = 2,
        };

        ToolbarItem selectedToolbar_ = ToolbarItem.Font;

        private void OnEnable()
        {
            lastFontSize_ = fontSize_;
            lastFallbackFontSize_ = fallbackFontSize_;
        }

        void OnDisable()
        {
            if (renderTexture_ != null)
                renderTexture_.Release();
        }

        void OnGUI()
        {
            bool updateTex = false;
            
            string[] toolbarNames = null;

            if( font_ != null )
            {
                toolbarNames = System.Enum.GetNames(typeof(ToolbarItem));
            }
            // If we haven't selected a font, only show the font gui.
            else
            {
                toolbarNames = new string[] { "Font" };
            }

            selectedToolbar_ = (ToolbarItem)GUILayout.Toolbar((int)selectedToolbar_, toolbarNames,  GUILayout.Height(40));

            EditorGUI.BeginChangeCheck();

            switch( selectedToolbar_ )
            {
                case ToolbarItem.Font:
                    DrawFontGUI();
                break;
                case ToolbarItem.Glyphs:
                    DrawGlyphGUI();
                break;
                case ToolbarItem.Atlas:
                    DrawAtlasGUI();
                break;
            }
            

            updateTex = EditorGUI.EndChangeCheck();

            // Track changes in font size. Since they can be changed externally we need to check against them 
            // constantly
            if( fontSize_ != lastFontSize_ )
            {
                lastFontSize_ = fontSize_;
                updateTex = true;
            }

            if( unsupportedGlyphHandling_ == UnsupportedGlyphHandling.Fallback &&
                fallbackFont_ != null && !fallbackFont_.dynamic &&
                 lastFallbackFontSize_ != fallbackFontSize_ )
            {
                lastFallbackFontSize_ = fallbackFontSize_;
                updateTex = true;
            }

            
            if ( font_ != null )
            {
                // Ensure our input string is up to date:
                UpdateSelectedGlyphs();

                // Parse our string if needed - before we update our texture
                if (!font_.dynamic)
                {
                    HandleUnsupportedGlyphs(ref glyphString_, ref fallbackString_, font_, fallbackFont_);
                }

                EditorGUILayout.LabelField("", GUI.skin.horizontalSlider);
                DrawPreviewGUI(updateTex);
            }
        }

        /// <summary>
        /// Prepare the given font to render our characters and build our mesh.
        /// </summary>
        /// <param name="mesh">The FontAtlasMesh to build.</param>
        /// <param name="font">The font to use.</param>
        /// <param name="fontSize">The fontsize to set.</param>
        /// <param name="input">The input string.</param>
        /// <param name="mat">The material to use for this font.</param>
        /// <param name="verticalAdjust">Vertical offset.</param>
        void SetupFontAndMesh(FontAtlasMesh mesh, Font font, int fontSize, string input, Material mat, int verticalAdjust )
        {
            font.RequestCharactersInTexture(input, fontSize);
            font.material.mainTexture.filterMode = FilterMode.Point;
            mat.mainTexture = font.material.mainTexture;
            mat.color = textColor_;

            mesh.AddCharactersToMesh(input, font, fontSize, columnCount_, glyphDimensions_, verticalAdjust);
        }

        /// <summary>
        /// Build the grab texture.
        /// </summary>
        void RebuildTexture(IntVector2 totalPixels)
        {

            // Ensure our grab texture is the proper size
            if (grabTexture_ == null || grabTexture_.width != totalPixels.x || grabTexture_.height != totalPixels.y)
            {
                grabTexture_ = new Texture2D(totalPixels.x, totalPixels.y);
                grabTexture_.filterMode = FilterMode.Point;
            }

            // Recreate our render texture if needed
            if (renderTexture_ == null || !renderTexture_.IsCreated() ||
                renderTexture_.width != totalPixels.x ||
                renderTexture_.height != totalPixels.y)
            {
                if (renderTexture_ != null)
                {
                    renderTexture_.Release();
                    renderTexture_ = null;
                }

                renderTexture_ = new RenderTexture(totalPixels.x, totalPixels.y, 0);
                renderTexture_.filterMode = FilterMode.Point;
                renderTexture_.Create();
                renderTexture_.hideFlags = HideFlags.HideAndDontSave;
            }

            // Render our mesh into our render texture.
            var lastRT = RenderTexture.active;

            RenderTexture.active = renderTexture_;

            GL.PushMatrix();
            GL.Clear(true, true, backgroundColor_);
            
            GL.LoadPixelMatrix(0,
                totalPixels.x, 0,
                totalPixels.y);

            SetupFontAndMesh(mesh_, font_, fontSize_, glyphString_, Material_, verticalOffset_);

            Material_.SetPass(0);

            // Render our primary mesh.
            Graphics.DrawMeshNow(mesh_.Mesh_, Vector3.zero, Quaternion.identity);
            
            // If we're using it, render our fallback mesh on top.
            if (!font_.dynamic && unsupportedGlyphHandling_ == UnsupportedGlyphHandling.Fallback && fallbackFont_ != null )
            {
                SetupFontAndMesh(fallbackMesh_, fallbackFont_, fallbackFontSize_, fallbackString_, FallbackMat_, fallbackVerticalOffset_);

                FallbackMat_.SetPass(0);

                Graphics.DrawMeshNow(fallbackMesh_.Mesh_, new Vector3(0, 0, -1), Quaternion.identity);
            }

            // Read our render into our grab texture.
            grabTexture_.ReadPixels(new Rect(0, 0, totalPixels.x, totalPixels.y), 0, 0);
            grabTexture_.Apply(false);

            GL.PopMatrix();

            RenderTexture.active = lastRT;
        }

        /// <summary>
        /// Draw the gui for the font.
        /// </summary>
        void DrawFontGUI()
        {
            EditorGUI.indentLevel++;
            {
                font_ = (Font)EditorGUILayout.ObjectField("Font", font_, typeof(Font), false);


                if (font_ != null)
                {
                    if (font_.dynamic)
                    {
                        fontSize_ = EditorGUILayout.IntField("Font Size", fontSize_);
                    }
                    else
                    {
                        var style = new GUIStyle(EditorStyles.label);
                        style.richText = true;
                        fontSize_ = font_.fontSize;
                        EditorGUILayout.LabelField("Current size: <b>" + font_.fontSize + "</b>", style );

                        EditorGUILayout.LabelField("For non-dynamic fonts size must be controlled from the asset in the project view. Make sure you hit apply after you change the size.", EditorStyles.wordWrappedLabel);
                    }
                }
            }
            EditorGUI.indentLevel--;
        }

        void DrawGlyphGUI()
        {
            EditorGUI.indentLevel++;
            {
                selectedGlyphs_ = (SelectedGlyphs)EditorGUILayout.EnumPopup("Characters", selectedGlyphs_);

                if( selectedGlyphs_ == SelectedGlyphs.Custom )
                {
                    EditorGUI.indentLevel++;
                    {
                        customString_ = EditorGUILayout.TextField("Custom Characters", customString_);
                    }
                    EditorGUI.indentLevel--;
                }

                glyphDimensions_.x = EditorGUILayout.IntField("Glyph Width", glyphDimensions_.x);
                glyphDimensions_.y = EditorGUILayout.IntField("Glyph Height", glyphDimensions_.y);
                string tooltip =
                    "Vertical offset applied to each glyph on the tilesheet. May need slight tweaking from font to font.";
                var vertOffsetContent = new GUIContent(
                    "Vertical Offset", tooltip);
                verticalOffset_ = EditorGUILayout.IntField(vertOffsetContent, verticalOffset_);

                EditorGUILayout.LabelField("Unsupported Glyph Handling", EditorStyles.boldLabel);
                EditorGUI.indentLevel++;
                {
                    if (font_.dynamic)
                    {
                        {
                            EditorGUILayout.LabelField("Font is currently set to dynamic. For dynamic fonts Unity doesn't provide" +
                                " a way to distinguis unsupported characters - they will automatically be replaced with fallback characters." +
                                " For unsupported glyph handling you must set the font asset to unicode in the project view.",
                                EditorStyles.wordWrappedLabel);
                        }

                    }
                    else
                    {
                        unsupportedGlyphHandling_ = 
                            (UnsupportedGlyphHandling)EditorGUILayout.EnumPopup(unsupportedGlyphHandling_);

                        if( unsupportedGlyphHandling_ == UnsupportedGlyphHandling.Fallback )
                        {
                            
                            fallbackFont_ = (Font)EditorGUILayout.ObjectField("Fallback Font", fallbackFont_, typeof(Font), false);

                            if( fallbackFont_ != null )
                            {
                                if (fallbackFont_.dynamic)
                                {
                                    fallbackFontSize_ = EditorGUILayout.IntField("Fallback Font Size", fallbackFontSize_);
                                }
                                fallbackVerticalOffset_ = EditorGUILayout.IntField("Fallback Vertical Offset", fallbackVerticalOffset_);
                            }
                           
                        }
                    }

                }
                EditorGUI.indentLevel--;

            }
            EditorGUI.indentLevel--;

        }

        void DrawAtlasGUI()
        {
            EditorGUI.indentLevel++;
            {
                backgroundColor_ = EditorGUILayout.ColorField("Background Color", backgroundColor_);

                textColor_ = EditorGUILayout.ColorField("Text Color", textColor_);

                columnCount_ = EditorGUILayout.IntField("Column Count", columnCount_);
            }
            EditorGUI.indentLevel--;
        }

        /// <summary>
        /// Draw the preview of our tile sheet.
        /// </summary>
        /// <param name="updateTex">Whether or not we need to rebuild our texture.</param>
        void DrawPreviewGUI(bool updateTex)
        {
            EditorGUILayout.LabelField("Preview", EditorStyles.boldLabel);

            EditorGUI.indentLevel++;
            {
                EditorGUILayout.BeginHorizontal();
                {
                    drawPreviewGrid_ = EditorGUILayout.Toggle("Draw Preview Grid", drawPreviewGrid_);
                    if (drawPreviewGrid_)
                    {
                        previewGridColor_ = EditorGUILayout.ColorField(previewGridColor_);
                    }
                }
                EditorGUILayout.EndHorizontal();
            }
            EditorGUI.indentLevel--;

            // Get the total pixel size of our tile sheet based on our grid and glyph settings
            int horGlyphCount = Mathf.Min(glyphString_.Length, columnCount_);
            int vertGlyphCount = Mathf.CeilToInt((float)glyphString_.Length / horGlyphCount);

            //Debug.Log("Glyph Count: " + new IntVector2(horGlyphCount, vertGlyphCount));

            IntVector2 totalPixels = new IntVector2(
                glyphDimensions_.x * horGlyphCount,
                glyphDimensions_.y * vertGlyphCount);

            if (font_ == null || string.IsNullOrEmpty(glyphString_) ||
                totalPixels.x <= 0 || totalPixels.y <= 0)
                return;

            // Calculate the maximum size for our preview image
            var area = GUILayoutUtility.GetRect(totalPixels.x, totalPixels.y, GUILayout.ExpandWidth(true), GUILayout.ExpandHeight(true));

            // Get our max scale that will maintain our aspect ratio
            var expandedHorScale = Mathf.Floor(area.width / totalPixels.x);
            var exandedVertScale = Mathf.Floor(area.height / totalPixels.y);
            var scale = Mathf.Min(expandedHorScale, exandedVertScale);

            var totalArea = area.size;

            // Determine our new scaled size
            var scaledSize = area.size;
            scaledSize.x = totalPixels.x * scale;
            scaledSize.y = totalPixels.y * scale;
            area.size = scaledSize;

            // Center our preview image
            var remaining = totalArea - scaledSize;
            area.position += remaining / 2f;

            // Rebuild our texture if any settings have changed
            if (updateTex )
            {
                RebuildTexture(totalPixels);
            }

            if (grabTexture_ != null)
            {
                GUI.DrawTexture(area, grabTexture_);
            }



            if (drawPreviewGrid_)
            {
                var transparent = new Color(1, 1, 1, 0);
                for (int x = 0; x < horGlyphCount; ++x)
                {
                    for (int y = 0; y < vertGlyphCount; ++y)
                    {
                        float t = (x + y) * .5f;
                        t = (t - Mathf.Floor(t)) * 2f;

                        var col = Color.Lerp(transparent, previewGridColor_, t);

                        var size = glyphDimensions_ * scale;

                        var pos = new Vector2(x * size.x, y * size.y) + area.position;

                        var cellArea = new Rect(pos, size);

                        EditorGUI.DrawRect(cellArea, col);
                    }
                }
            }

            DrawWriteToDiskButton();
        }

        void DrawWriteToDiskButton()
        {
            var oldColor = GUI.color;
            GUI.color = Color.green;

            EditorGUILayout.BeginHorizontal();
            GUILayout.FlexibleSpace();
            if (GUILayout.Button("Write To Disk", GUILayout.Width(100), GUILayout.Height(25)))
            {
                var fileName = font_.name + " Atlas";
                var path = EditorUtility.SaveFilePanelInProject("Save Texture", fileName, "png", "Save Font Atlas");

                if (!string.IsNullOrEmpty(path))
                {
                    var bytes = grabTexture_.EncodeToPNG();

                    if (bytes != null)
                    {
                        System.IO.File.WriteAllBytes(path, bytes);
                        AssetDatabase.Refresh();
                    }
                    else
                        Debug.LogErrorFormat("Error writing texture to disk");
                }
            }
            GUILayout.FlexibleSpace();
            EditorGUILayout.EndHorizontal();

            GUI.color = oldColor;
        }

        void UpdateSelectedGlyphs()
        {
            switch (selectedGlyphs_)
            {
                case SelectedGlyphs.Custom:
                {
                    glyphString_ = customString_;
                }
                break;

                case SelectedGlyphs.Code_Page_437:
                    glyphString_ = CODE_PAGE_437_STR_;
                break;
            }
        }


        public static string CleanString(string str, HashSet<char> toRemove )
        {
            var result = new System.Text.StringBuilder(str.Length);

            for (int i = 0; i < str.Length; i++)
            {
                if (!toRemove.Contains(str[i]))
                    result.Append(str[i]);
            }
            return result.ToString();
        }

        string HandleUnsupportedGlyphs(ref string input, ref string fallbackString, Font font, Font fallbackFont)
        {
            HashSet<char> toRemove = new HashSet<char>();

            foreach (char ch in input)
            {
                if (!font.HasCharacter(ch))
                {
                    toRemove.Add(ch);
                }
            }

            switch (unsupportedGlyphHandling_)
            {
                case UnsupportedGlyphHandling.Empty:
                {
                    foreach (char ch in toRemove)
                    {
                        input = input.Replace(ch, ' ');
                    }
                }
                break;

                case UnsupportedGlyphHandling.Remove:
                {
                    input = CleanString(input, toRemove);
                }
                break;

                case UnsupportedGlyphHandling.Fallback:
                {
                    if( fallbackFont_ == null )
                    {
                        foreach (char ch in toRemove)
                        {
                            input = input.Replace(ch, ' ');
                        }
                    }
                    else 
                    {
                        // Copy our input to fallback.
                        fallbackString = input;

                        // Run through each char in our input
                        for (int i = 0; i < input.Length; ++i)
                        {
                            char ch = input[i];

                            // Remove characters that our primary font has or
                            // that our fallback font doesn't
                            if (font.HasCharacter(ch) || !fallbackFont.HasCharacter(ch))
                            {
                                // If this isn't a fallback character or if our fallback
                                // character isn't in our fallback font then we'll blank
                                // it out on our fallback string

                                // This will leave us with a string of the identical length
                                // to the input but all non-fallback-able chars blanked out
                                fallbackString = fallbackString.Replace(ch, ' ');
                            }

                            if (!font.HasCharacter(ch))
                            {
                                input = input.Replace(ch, ' ');
                            }

                        }
                    }

                    //Debug.Log("Input: " + input);
                    //Debug.Log("Fallback: " + fallbackString);
                    
                }
                break;
            }
            return input;
        }
    }

}
