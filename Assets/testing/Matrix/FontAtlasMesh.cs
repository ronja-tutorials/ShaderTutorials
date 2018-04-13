using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;
using FontAtlasGen.Util;

namespace FontAtlasGen
{
    /// <summary>
    /// Mesh used to build glyphs into a tilesheet style mesh.
    /// </summary>
    public class FontAtlasMesh
    {
        /// <summary>
        /// Internal mesh, should never be acceessed outside it's property.
        /// </summary>
        [System.NonSerialized]
        Mesh mesh_;

        List<int> tris_ = new List<int>();
        List<Vector3> verts_ = new List<Vector3>();
        List<Vector2> uvs_ = new List<Vector2>();

        /// <summary>
        /// The internal mesh. Won't contain anything useful until
        /// <seealso cref="AddCharactersToMesh(string, Font, int, int, IntVector2, int)"/> is called.
        /// </summary>
        public Mesh Mesh_
        {
            get
            {
                if (mesh_ == null)
                {
                    mesh_ = new Mesh();
                    mesh_.hideFlags = HideFlags.HideAndDontSave;
                }
                return mesh_;
            }
        }

        /// <summary>
        /// Clears all mesh data.
        /// </summary>
        void ClearData()
        {
            verts_.Clear();
            tris_.Clear();
            uvs_.Clear();
        }

        /// <summary>
        /// Build the given characters into the mesh with the given parameters.
        /// </summary>
        /// <param name="charString">The characters to build into the mesh. They will be written in order with no filtering applied.</param>
        /// <param name="font">The font to draw our characters from.</param>
        /// <param name="fontSize">The font size when retrieving characters from the font.</param>
        /// <param name="xCount">How many glyphs to draw in a row before moving to the next row.</param>
        /// <param name="glyphDimensions">The dimensions of each glyph.</param>
        /// <param name="verticalAdjust">Vertical offset applied to each glyph. Proper value varies from font to font.</param>
        public void AddCharactersToMesh(string charString, Font font, int fontSize, int xCount, IntVector2 glyphDimensions, int verticalAdjust)
        {
            font.RequestCharactersInTexture(charString, fontSize);

            if (string.IsNullOrEmpty(charString))
            {
                Debug.LogError("Input string null or empty");
                return;
            }

            ClearData();

            var mesh = Mesh_;

            mesh.Clear();
            
            int yCount = Mathf.CeilToInt((float)charString.Length / xCount);
            int charIndex = 0;
            
            for (int y = yCount - 1; y >= 0; --y)
            {
                for (int x = 0; x < xCount && charIndex < charString.Length; ++x)
                {
                    char ch = charString[charIndex++];

                    CharacterInfo charInfo;
                    font.GetCharacterInfo(ch, out charInfo, fontSize);

                    AddVertsAndTris(x, y, charInfo, glyphDimensions, verticalAdjust);

                    AddUVs(charInfo);
                }
            }
            

            mesh.SetVertices(verts_);
            mesh.SetTriangles(tris_, 0);
            mesh.SetUVs(0, uvs_);

        }

        /// <summary>
        /// Add vertex and triangle data for a single glyph at the given position.
        /// </summary>
        /// <param name="cellX">The horizontal cell index to draw into.</param>
        /// <param name="cellY">The vertical cell index to draw into.</param>
        /// <param name="charInfo">Character info from the font.</param>
        /// <param name="cellDimensions">The dimensions of a single cell.</param>
        /// <param name="verticalAdjust">Vertical offset applied to each glyph, the proper value varies from font to font.
        /// Tweak it until all glyphs are entirely contained within their cells.</param>
        void AddVertsAndTris(int cellX, int cellY, CharacterInfo charInfo, IntVector2 cellDimensions, int verticalAdjust)
        {
            // Bottom left position of our cell.
            var cellPos = new Vector3(cellDimensions.x * cellX, cellDimensions.y * cellY);

            // Local corners for our cell vertices.
            var bl = new Vector3(charInfo.minX, charInfo.minY + verticalAdjust);
            var tl = new Vector3(charInfo.minX, charInfo.maxY + verticalAdjust);
            var tr = new Vector3(charInfo.maxX, charInfo.maxY + verticalAdjust);
            var br = new Vector3(charInfo.maxX, charInfo.minY + verticalAdjust);

            // Verts layed out like so:
            // 0--1
            // |  |
            // |  |
            // 2--3
            verts_.Add(cellPos + tl);
            verts_.Add(cellPos + tr);
            verts_.Add(cellPos + bl);
            verts_.Add(cellPos + br);

            var vertIndex = ((verts_.Count / 4) - 1) * 4;
            for (int i = 0; i < 6; ++i)
            {
                tris_.Add(vertIndex + defaultTris_[i]);
            }
        }

        void AddUVs(CharacterInfo charInfo)
        {
            uvs_.Add(charInfo.uvTopLeft);
            uvs_.Add(charInfo.uvTopRight);
            uvs_.Add(charInfo.uvBottomLeft);
            uvs_.Add(charInfo.uvBottomRight);
        }


        static int[] defaultTris_ = new int[]
        {
        0,1,2,3,2,1
        };
    }

}
