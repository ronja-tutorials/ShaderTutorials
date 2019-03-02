/*
 * Copyright 2012, Catlike Coding
 * http://catlikecoding.com
 */
/*
	Based on the Anti-aliased Euclidean distance transform described by Stefan Gustavson and Robin Strand.
	See http://webstaff.itn.liu.se/~stegu/edtaa/ and http://contourtextures.wikidot.com/ for further information.
	
	The algorithm is an adapted version of Stefan Gustavson's code, it inherits the following copyright statement,
	which applies to this file only.

	Copyright (C) 2012 Jasper Flick (http://catlikecoding.com) for adaptation to C# for Unity.
	Copyright (C) 2009 Stefan Gustavson (stefan.gustavson@gmail.com)

	This software is distributed under the permissive "MIT License":

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
 */

using UnityEngine;

namespace CatlikeCoding.SDFToolkit {

	/// <summary>
	/// How to fill the RGB channels of a generated singed distance field texture.
	/// </summary>
	public enum RGBFillMode {
		/// <summary>
		/// Set the RGB channels to 1.
		/// </summary>
		White,
		/// <summary>
		/// Set the RGB channels to 0.
		/// </summary>
		Black,
		/// <summary>
		/// Set the RGB channels to the generated distance field.
		/// </summary>
		Distance,
		/// <summary>
		/// Copy the source texture's RGB channels.
		/// </summary>
		Source
	}

	/// <summary>
	/// Utility class for generating signed distance field textures from anti-aliased alpha maps.
	/// </summary>
	/// <description>
	/// Although the generator can be used at run-time, the current version isn't convenient nor optimized for it.
	/// </description>
	public static class SDFTextureGenerator {
		
		private class Pixel {
			public float alpha, distance;
			public Vector2 gradient;
			public int dX, dY;
		}
		
		private static int width, height;
		private static Pixel[,] pixels;
		
		/// <summary>
		/// Fill a texture with a signed distance field generated from the alpha channel of a source texture.
		/// </summary>
		/// <param name="source">
		/// Source texture. Alpha values of 1 are considered inside, values of 0 are considered outside, and any other values are considered
		/// to be on the edge. Must be readable.
		/// </param>
		/// <param name="destination">
		/// Destination texture. Must be the same size as the source texture. Must be readable.
		/// The texture change does not get applied automatically, you need to do that yourself.
		/// </param>
		/// <param name="maxInside">
		/// Maximum pixel distance measured inside the edge, resulting in an alpha value of 1.
		/// If set to or below 0, everything inside will have an alpha value of 1.
		/// </param>
		/// <param name="maxOutside">
		/// Maximum pixel distance measured outside the edge, resulting in an alpha value of 0.
		/// If set to or below 0, everything outside will have an alpha value of 0.
		/// </param>
		/// <param name="postProcessDistance">
		/// Pixel distance from the edge within which pixels will be post-processed using the edge gradient.
		/// </param>
		/// <param name="rgbMode">
		/// How to fill the destination texture's RGB channels.
		/// </param>
		public static void Generate (
			Texture2D source,
			Texture2D destination,
			float maxInside,
			float maxOutside,
			float postProcessDistance,
			RGBFillMode rgbMode) {

			if(source.height != destination.height || source.width != destination.width){
				Debug.LogError("Source and destination textures must be the same size.");
				return;
			}

			width = source.width;
			height = source.height;
			pixels = new Pixel[width, height];
			int x, y;
			float scale;
			Color c = rgbMode == RGBFillMode.White ? Color.white : Color.black;
			for(y = 0; y < height; y++){
				for(x = 0; x < width; x++){
					pixels[x, y] = new Pixel();
				}
			}
			if(maxInside > 0f){
				for(y = 0; y < height; y++){
					for(x = 0; x < width; x++){
						pixels[x, y].alpha = 1f - source.GetPixel(x, y).a;
					}
				}
				ComputeEdgeGradients();
				GenerateDistanceTransform();
				if(postProcessDistance > 0f){
					PostProcess(postProcessDistance);
				}
				scale = 1f / maxInside;
				for(y = 0; y < height; y++){
					for(x = 0; x < width; x++){
						c.a = Mathf.Clamp01(pixels[x, y].distance * scale);
						destination.SetPixel(x, y, c);
					}
				}
			}
			if(maxOutside > 0f){
				for(y = 0; y < height; y++){
					for(x = 0; x < width; x++){
						pixels[x, y].alpha = source.GetPixel(x, y).a;
					}
				}
				ComputeEdgeGradients();
				GenerateDistanceTransform();
				if(postProcessDistance > 0f){
					PostProcess(postProcessDistance);
				}
				scale = 1f / maxOutside;
				if(maxInside > 0f){
					for(y = 0; y < height; y++){
						for(x = 0; x < width; x++){
							c.a = 0.5f + (destination.GetPixel(x, y).a -
							              Mathf.Clamp01(pixels[x, y].distance * scale)) * 0.5f;
							destination.SetPixel(x, y, c);
						}
					}
				}
				else{
					for(y = 0; y < height; y++){
						for(x = 0; x < width; x++){
							c.a = Mathf.Clamp01(1f - pixels[x, y].distance * scale);
							destination.SetPixel(x, y, c);
						}
					}
				}
			}
			
			if(rgbMode == RGBFillMode.Distance){
				for(y = 0; y < height; y++){
					for(x = 0; x < width; x++){
						c = destination.GetPixel(x, y);
						c.r = c.a;
						c.g = c.a;
						c.b = c.a;
						destination.SetPixel(x, y, c);
					}
				}
			}
			else if(rgbMode == RGBFillMode.Source){
				for(y = 0; y < height; y++){
					for(x = 0; x < width; x++){
						c = source.GetPixel(x, y);
						c.a = destination.GetPixel(x, y).a;
						destination.SetPixel(x, y, c);
					}
				}
			}
			pixels = null;
		}
		
		private static void ComputeEdgeGradients () {
			float sqrt2 = Mathf.Sqrt(2f);
			for(int y = 1; y < height - 1; y++){ 
				for(int x = 1; x < width - 1; x++){
					Pixel p = pixels[x, y];
					if(p.alpha > 0f && p.alpha < 1f){
						// estimate gradient of edge pixel using surrounding pixels
						float g =
							- pixels[x - 1, y - 1].alpha
							- pixels[x - 1, y + 1].alpha
							+ pixels[x + 1, y - 1].alpha
							+ pixels[x + 1, y + 1].alpha;
						p.gradient.x = g + (pixels[x + 1, y].alpha - pixels[x - 1, y].alpha) * sqrt2;
						p.gradient.y = g + (pixels[x, y + 1].alpha - pixels[x, y - 1].alpha) * sqrt2;
						p.gradient.Normalize();
					}
				}
			}
		}
		
		private static float ApproximateEdgeDelta (float gx, float gy, float a) {
			// (gx, gy) can be either the local pixel gradient or the direction to the pixel
			
			if(gx == 0f || gy == 0f){
				// linear function is correct if both gx and gy are zero
				// and still fair if only one of them is zero
				return 0.5f - a;
			}
			
			// normalize (gx, gy)
			float length = Mathf.Sqrt(gx * gx + gy * gy);
			gx = gx / length;
			gy = gy / length;
			
			// reduce symmetrical equation to first octant only
			// gx >= 0, gy >= 0, gx >= gy
			gx = Mathf.Abs(gx);
			gy = Mathf.Abs(gy);
			if(gx < gy){
				float temp = gx;
				gx = gy;
				gy = temp;
			}
			
			// compute delta
			float a1 = 0.5f * gy / gx;
			if(a < a1){
				// 0 <= a < a1
				return 0.5f * (gx + gy) - Mathf.Sqrt(2f * gx * gy * a);
			}
			if(a < (1f - a1)){
				// a1 <= a <= 1 - a1
				return (0.5f - a) * gx;
			}
			// 1-a1 < a <= 1
			return -0.5f * (gx + gy) + Mathf.Sqrt(2f * gx * gy * (1f - a));
		}
		
		private static void UpdateDistance (Pixel p, int x, int y, int oX, int oY) {
			Pixel neighbor = pixels[x + oX, y + oY];
			Pixel closest = pixels[x + oX - neighbor.dX, y + oY - neighbor.dY];
			
			if(closest.alpha == 0f || closest == p){
				// neighbor has no closest yet
				// or neighbor's closest is p itself
				return;
			}
			
			int dX = neighbor.dX - oX;
			int dY = neighbor.dY - oY;
			float distance = Mathf.Sqrt(dX * dX + dY * dY) + ApproximateEdgeDelta(dX, dY, closest.alpha);
			if(distance < p.distance){
				p.distance = distance;
				p.dX = dX;
				p.dY = dY;
			}
		}
		
		private static void GenerateDistanceTransform () {
			// perform anti-aliased Euclidean distance transform
			int x, y;
			Pixel p;
			
			// initialize distances
			for(y = 0; y < height; y++){ 
				for(x = 0; x < width; x++){
					p = pixels[x, y];
					p.dX = 0;
					p.dY = 0;
					if(p.alpha <= 0f){
						// outside
						p.distance = 1000000f;
					}
					else if (p.alpha < 1f){
						// on the edge
						p.distance = ApproximateEdgeDelta(p.gradient.x, p.gradient.y, p.alpha);
					}
					else{
						// inside
						p.distance = 0f;
					}
				}
			}
			// perform 8SSED (eight-points signed sequential Euclidean distance transform)
			// scan up
			for(y = 1; y < height; y++){
				// |P.
				// |XX
				p = pixels[0, y];
				if(p.distance > 0f){
					UpdateDistance(p, 0, y, 0, -1);
					UpdateDistance(p, 0, y, 1, -1);
				}
				// -->
				// XP.
				// XXX
				for(x = 1; x < width - 1; x++){
					p = pixels[x, y];
					if(p.distance > 0f){
						UpdateDistance(p, x, y, -1, 0);
						UpdateDistance(p, x, y, -1, -1);
						UpdateDistance(p, x, y, 0, -1);
						UpdateDistance(p, x, y, 1, -1);
					}
				}
				// XP|
				// XX|
				p = pixels[width - 1, y];
				if(p.distance > 0f){
					UpdateDistance(p, width - 1, y, -1, 0);
					UpdateDistance(p, width - 1, y, -1, -1);
					UpdateDistance(p, width - 1, y, 0, -1);
				}
				// <--
				// .PX
				for(x = width - 2; x >= 0; x--){
					p = pixels[x, y];
					if(p.distance > 0f){
						UpdateDistance(p, x, y, 1, 0);
					}
				}			
			}
			// scan down
			for(y = height - 2; y >= 0; y--){
				// XX|
				// .P|
				p = pixels[width - 1, y];
				if(p.distance > 0f){
					UpdateDistance(p, width - 1, y, 0, 1);
					UpdateDistance(p, width - 1, y, -1, 1);
				}
				// <--
				// XXX
				// .PX
				for(x = width - 2; x > 0; x--){
					p = pixels[x, y];
					if(p.distance > 0f){
						UpdateDistance(p, x, y, 1, 0);
						UpdateDistance(p, x, y, 1, 1);
						UpdateDistance(p, x, y, 0, 1);
						UpdateDistance(p, x, y, -1, 1);
					}
				}
				// |XX
				// |PX
				p = pixels[0, y];
				if(p.distance > 0f){
					UpdateDistance(p, 0, y, 1, 0);
					UpdateDistance(p, 0, y, 1, 1);
					UpdateDistance(p, 0, y, 0, 1);
				}
				// -->
				// XP.
				for(x = 1; x < width; x++){
					p = pixels[x, y];
					if(p.distance > 0f){
						UpdateDistance(p, x, y, -1, 0);
					}
				}
			}
		}
		
		private static void PostProcess (float maxDistance) {
			// adjust distances near edges based on the local edge gradient
			for(int y = 0; y < height; y++){
				for(int x = 0; x < width; x++){
					Pixel p = pixels[x, y];
					if((p.dX == 0 && p.dY == 0) || p.distance >= maxDistance){
						// ignore edge, inside, and beyond max distance
						continue;
					}
					float
						dX = p.dX,
						dY = p.dY;
					Pixel closest = pixels[x - p.dX, y - p.dY];
					Vector2 g = closest.gradient;
					
					if(g.x == 0f && g.y == 0f){
						// ignore unknown gradients (inside)
						continue;
					}
					
					// compute hit point offset on gradient inside pixel
					float df = ApproximateEdgeDelta(g.x, g.y, closest.alpha);
					float t = dY * g.x - dX * g.y;
					float u = -df * g.x + t * g.y;
					float v = -df * g.y - t * g.x;
					
					// use hit point to compute distance
					if(Mathf.Abs(u) <= 0.5f && Mathf.Abs(v) <= 0.5f){
						p.distance = Mathf.Sqrt((dX + u) * (dX + u) + (dY + v) * (dY + v));
					}
				}
			}
		}
	}
}