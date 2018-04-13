using UnityEngine;

namespace FontAtlasGen.Util
{
    [System.Serializable]
    public struct IntVector2 : System.IEquatable<IntVector2>
    {
        //
        // Fields
        //
        public int x, y;

        //
        // Constructors
        //
        public IntVector2(int x, int y)
        {
            this.x = x;
            this.y = y;
        }

        public IntVector2(float x, float y)
        {
            this.x = Mathf.FloorToInt(x);
            this.y = Mathf.FloorToInt(y);
        }

        public IntVector2(Vector2 vec) : this(vec.x, vec.y) { }

        //
        // Static Properties
        //
        public static IntVector2 one { get { return new IntVector2(1, 1); } }

        public static IntVector2 right { get { return new IntVector2(1, 0); } }
        public static IntVector2 up { get { return new IntVector2(0, 1); } }
        public static IntVector2 down { get { return new IntVector2(0, -1); } }
        public static IntVector2 left { get { return new IntVector2(-1, 0); } }

        public static IntVector2 zero { get { return new IntVector2(0, 0); } }

        //
        // Properties
        //
        public float magnitude
        {
            get
            {
                return Mathf.Sqrt(this.x * this.x + this.y * this.y);
            } 
        }

        /// <summary>
        /// Returns an IntVector2 with a magnitude of 1
        /// </summary>
        public IntVector2 normalized
        {
            get
            {
                // Reduce our greater element to 1 without changing the sign and we
                int absX = Mathf.Abs(x);
                int absY = Mathf.Abs(y);
                if( absX > absY )
                {
                    x /= absX;
                    y = 0;
                }
                else if ( absY > absX )
                {
                    x = 0;
                    y /= absY;
                }

                return this;
            }
        }

        public int sqrMagnitude
        {
            get
            {
                return this.x * this.x + this.y * this.y;
            }
        }


        /// <summary>
        /// The manhattan distance between two points (The positive distance to 
        /// reach b from a while moving on a four-directional grid)
        /// </summary>
        public static int ManhattanDistance(IntVector2 a, IntVector2 b)
        {
            return Mathf.Abs(b.x - a.x) + Mathf.Abs(b.y - a.y);
        }

        public static IntVector2 RoundedVec(Vector2 a)
        {
            a.x = Mathf.Round(a.x);
            a.y = Mathf.Round(a.y);
            return new IntVector2((int)a.x, (int)a.y);
        }

        /// <summary>
        /// Distance from origin to the end of the vector as measured at right angles.
        /// </summary>
        public int manhattanDistance
        {
            get
            {
                return Mathf.Abs(x) + Mathf.Abs(y);
            }
        }

        //
        // Indexer
        //
        public int this[int index]
        {
            get
            {
                if (index == 0)
                {
                    return this.x;
                }
                if (index != 1)
                {
                    throw new System.IndexOutOfRangeException("Invalid IntVector2 index!");
                }
                return this.y;
            }
            set
            {
                if (index != 0)
                {
                    if (index != 1)
                    {
                        throw new System.IndexOutOfRangeException("Invalid IntVector2 index!");
                    }
                    this.y = value;
                }
                else
                {
                    this.x = value;
                }
            }
        }



        //
        // Static Methods
        //
        public static float Angle(IntVector2 from, IntVector2 to)
        {
            return Vector2.Angle((Vector2)from, (Vector2)to);
        }

        public static IntVector2 ClampMagnitude(IntVector2 vector, float maxLength)
        {
            if (vector.sqrMagnitude > maxLength * maxLength)
            {
                return vector.normalized * maxLength;
            }
            return vector;
        }

        public static IntVector2 Clamp( IntVector2 vec, int minValue, int maxValue )
        {
            for (int i = 0; i < 2; ++i)
                vec[i] = Mathf.Clamp(vec[i], minValue, maxValue);

            return vec;
        }

        public static IntVector2 Clamp( IntVector2 vec, IntVector2 min, IntVector2 max )
        {
            for( int i = 0; i < 2; ++i )
            {
                vec[i] = Mathf.Clamp(vec[i], min[i], max[i]);
            }

            return vec;
        }

        public static float Distance(IntVector2 a, IntVector2 b)
        {
            return (a - b).magnitude;
        }

        public static int Dot(IntVector2 lhs, IntVector2 rhs)
        {
            return lhs.x * rhs.x + lhs.y * rhs.y;
        }

        public static IntVector2 Lerp(IntVector2 from, IntVector2 to, float t)
        {
            t = Mathf.Clamp01(t);
            return new IntVector2(from.x + (to.x - from.x) * t, from.y + (to.y - from.y) * t);
        }

        public static IntVector2 Max(IntVector2 lhs, IntVector2 rhs)
        {
            return new IntVector2(Mathf.Max(lhs.x, rhs.x), Mathf.Max(lhs.y, rhs.y));
        }

        public static IntVector2 Max(IntVector2 vec, int val )
        {
            return Max(vec, new IntVector2(val, val) );
        }

        public static IntVector2 Min(IntVector2 lhs, IntVector2 rhs)
        {
            return new IntVector2(Mathf.Min(lhs.x, rhs.x), Mathf.Min(lhs.y, rhs.y));
        }

        public static IntVector2 Abs( IntVector2 vec )
        {
            vec.x = Mathf.Abs(vec.x);
            vec.y = Mathf.Abs(vec.y);
            return vec;
        }

        public static IntVector2 MoveTowards(IntVector2 current, IntVector2 target, float maxDistanceDelta)
        {
            IntVector2 a = target - current;
            float magnitude = a.magnitude;
            if (magnitude <= maxDistanceDelta || magnitude == 0f)
            {
                return target;
            }
            return current + a / magnitude * maxDistanceDelta;
        }

        public static IntVector2 Scale(IntVector2 a, IntVector2 b)
        {
            return new IntVector2(a.x * b.x, a.y * b.y);
        }


        public static float SqrMagnitude(IntVector2 a)
        {
            return a.x * a.x + a.y * a.y;
        }

        //
        // Methods
        //
        public override bool Equals(object other)
        {
            if (!(other is IntVector2))
            {
                return false;
            }
            IntVector2 vector = (IntVector2)other;
            return this.x.Equals(vector.x) && this.y.Equals(vector.y);
        }

        // IEquatable ( Prevents allocations if we use this in dictionaries/hashtables)
        public bool Equals(IntVector2 other)
        {
            return x == other.x && y == other.y;
        }

        //http://stackoverflow.com/questions/263400/what-is-the-best-algorithm-for-an-overridden-system-object-gethashcode/263416#263416
        public override int GetHashCode()
        {
            unchecked // Overflow is fine, just wrap
            {
                int hash = 17;
                hash = hash * 23 + x.GetHashCode();
                hash = hash * 23 + y.GetHashCode();
                return hash;
            }
        }

        public void Normalize()
        {
            float magnitude = this.magnitude;
            if (magnitude > 1E-05f)
            {
                this /= magnitude;
            }
            else
            {
                this = IntVector2.zero;
            }
        }

        public void Scale(IntVector2 scale)
        {
            this.x *= scale.x;
            this.y *= scale.y;
        }

        public void Set(int new_x, int new_y)
        {
            this.x = new_x;
            this.y = new_y;
        }

        public float SqrMagnitude()
        {
            return this.x * this.x + this.y * this.y;
        }


        public override string ToString()
        {
            return string.Format("({0},{1})", x, y);
        }

        //
        // Operators
        //
        public static IntVector2 operator +(IntVector2 a, IntVector2 b)
        {
            return new IntVector2(a.x + b.x, a.y + b.y);
        }

        public static IntVector2 operator /(IntVector2 a, float d)
        {
            return new IntVector2(a.x / d, a.y / d);
        }

        public static bool operator ==(IntVector2 lhs, IntVector2 rhs)
        {
            return lhs.x == rhs.x && lhs.y == rhs.y;
        }



        public static implicit operator Vector2(IntVector2 v)
        {
            return new Vector2(v.x, v.y);
        }

        public static implicit operator Vector3(IntVector2 v)
        {
            return new Vector3(v.x, v.y, 0);
        }

        public static explicit operator IntVector2( Vector2 v )
        {
            return new IntVector2(v.x, v.y);
        }

        public static explicit operator IntVector2( Vector3 v )
        {
            return new IntVector2(v.x, v.y);
        }


        public static bool operator !=(IntVector2 lhs, IntVector2 rhs)
        {
            return !(lhs == rhs);
        }

        public static IntVector2 operator *(float d, IntVector2 a)
        {
            return new IntVector2(a.x * d, a.y * d);
        }

        public static IntVector2 operator *(IntVector2 a, float d)
        {
            return new IntVector2(a.x * d, a.y * d);
        }

        public static IntVector2 operator -(IntVector2 a, IntVector2 b)
        {
            return new IntVector2(a.x - b.x, a.y - b.y);
        }

        public static IntVector2 operator -(IntVector2 a)
        {
            return new IntVector2(-a.x, -a.y);
        }

        public static IntVector2 FlooredVector( Vector2 vec )
        {
            int x = Mathf.FloorToInt(vec.x);
            int y = Mathf.FloorToInt(vec.y);
            return new IntVector2(x, y);
        }


    }
}
