-----------------------------------------------------------------------------
--
-- Module      :  ST.Matrix4
-- Copyright   :  Michael Karg
-- License     :  Apache-2.0
--
-- Maintainer  :  jnf@arcor.de
-- Stability   :
-- Portability :
--
-- | Inspired by Mjs library for javascript
--
-----------------------------------------------------------------------------

module Data.ST.Matrix4 where

import Data.TypeNat
import Data.Matrix4 (Vec3N())
import Data.ST.Matrix
import qualified Data.Vector3 as V3
import qualified Data.Vector as V
import Control.Monad.Eff
import Control.Monad.ST (ST())
-- import Control.Apply
import Data.Array
import Data.Array.ST hiding (freeze, thaw)
import Prelude.Unsafe
import Math


type STMat4 h = STMat Four h Number

{-
identityST :: forall h r. Eff (st :: ST h | r) (STMat Four h Number)
identityST = do
    r <- thaw [1,0,0,0,
              0,1,0,0,
              0,0,1,0,
              0,0,0,1]
    return (STMat r)
-}

foreign import identityST """
    function identityST() {
        var as = [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1];
        return as;
    }""" :: forall h r. Eff (st :: ST h | r) (STMat Four h Number)

{-
-- | Computes the inverse of the given matrix m, assuming that the matrix is
--   orthonormal.
inverseOrthonormal :: Mat4 -> Mat4
inverseOrthonormal v@(Mat [x11, x12, x13, x14, x21, x22, x23, x24, x31, x32, x33, x34, x41, x42, x43, x44]) =
  case transpose v of
    Mat [y11, y12, y13, y14, y21, y22, y23, y24, y31, y32, y33, y34, y41, y42, y43, y44] ->
      let
        t = V.Vec [x41, x42, x43]
        r12 = negate (V.dot (V.Vec [y11,y21,y31]) t)
        r13 = negate (V.dot (V.Vec [y12,y22,y32]) t)
        r14 = negate (V.dot (V.Vec [y13,y23,y33]) t)
      in Mat [y11, y12, y13, 0, y21, y22, y23, 0, y31, y32, y33, 0, r12, r13, r14, y44]

-- | Creates a matrix for a projection frustum with the given parameters.
-- Parameters:
-- * left - the left coordinate of the frustum
-- * right- the right coordinate of the frustum
-- * bottom - the bottom coordinate of the frustum
-- * top - the top coordinate of the frustum
-- * znear - the near z distance of the frustum
-- * zfar - the far z distance of the frustum

makeFrustum :: Number -> Number -> Number -> Number -> Number -> Number -> Mat4
makeFrustum left right bottom top znear zfar =
  let x = 2*znear/(right-left)
      y = 2*znear/(top-bottom)
      z = (right+left)/(right-left)
      b = (top+bottom)/(top-bottom)
      c = -(zfar+znear)/(zfar-znear)
      d = -2*zfar*znear/(zfar-znear)
  in Mat [2*znear/(right-left),0,0,0,
          0,2*znear/(top-bottom),0,0,
          (right+left)/(right-left),(top+bottom)/(top-bottom),-(zfar+znear)/(zfar-znear),(-1),
          0,0,(-2)*zfar*znear/(zfar-znear),0]

-- | Creates a matrix for a perspective projection with the given parameters.
-- Parameters:
-- * fovy - field of view in the y axis, in degrees
-- * aspect - aspect ratio
-- * znear - the near z distance of the projection
-- * zfar - the far z distance of the projection
makePerspective :: Number -> Number -> Number -> Number -> Mat4
makePerspective fovy aspect znear zfar =
  let ymax = znear * tan(fovy * pi / 360.0)
      ymin = -ymax
      xmin = ymin * aspect
      xmax = ymax * aspect
  in makeFrustum xmin xmax ymin ymax znear zfar


-- | Creates a matrix for an orthogonal frustum projection with the given parameters.
-- Parameters:
-- * left - the left coordinate of the frustum
-- * right- the right coordinate of the frustum
-- * bottom - the bottom coordinate of the frustum
-- * top - the top coordinate of the frustum
-- * znear - the near z distance of the frustum
-- * zfar - the far z distance of the frustum
makeOrtho :: Number -> Number -> Number -> Number -> Number -> Number -> Mat4
makeOrtho left right bottom top znear zfar =
  let tX = -(right+left)/(right-left)
      tY = -(top+bottom)/(top-bottom)
      tZ = -(zfar+znear)/(zfar-znear)
      x = 2 / (right-left)
      y = 2 / (top-bottom)
      z = -2 / (zfar-znear)
  in Mat [x,0,0,0,
          0,y,0,0,
          0,0,z,0,
          tX,tY,tZ,1]


-- | Creates a matrix for a 2D orthogonal frustum projection with the given
-- parameters. `znear` and `zfar` are assumed to be -1 and 1, respectively.
-- Parameters:
-- * left - the left coordinate of the frustum
-- * right- the right coordinate of the frustum
-- * bottom - the bottom coordinate of the frustum
-- * top - the top coordinate of the frustum
makeOrtho2D :: Number -> Number -> Number -> Number -> Mat4
makeOrtho2D left right bottom top = makeOrtho left right bottom top (-1) 1

-- | Matrix multiplcation: a * b
mul :: Mat4 -> Mat4 -> Mat4
mul (Mat [x11, x21, x31, x41, x12, x22, x32, x42, x13, x23, x33, x43, x14, x24, x34, x44])
    (Mat [y11, y21, y31, y41, y12, y22, y32, y42, y13, y23, y33, y43, y14, y24, y34, y44]) =
     Mat [x11 * y11 + x12 * y21 + x13 * y31 + x14 * y41,
              x21 * y11 + x22 * y21 + x23 * y31 + x24 * y41,
                x31 * y11 + x32 * y21 + x33 * y31 + x34 * y41,
                  x41 * y11 + x42 * y21 + x43 * y31 + x44 * y41,
           x11 * y12 + x12 * y22 + x13 * y32 + x14 * y42,
              x21 * y12 + x22 * y22 + x23 * y32 + x24 * y42,
                x31 * y12 + x32 * y22 + x33 * y32 + x34 * y42,
                  x41 * y12 + x42 * y22 + x43 * y32 + x44 * y42,
            x11 * y13 + x12 * y23 + x13 * y33 + x14 * y43,
              x21 * y13 + x22 * y23 + x23 * y33 + x24 * y43,
                x31 * y13 + x32 * y23 + x33 * y33 + x34 * y43,
                  x41 * y13 + x42 * y23 + x43 * y33 + x44 * y43,
            x11 * y14 + x12 * y24 + x13 * y34 + x14 * y44,
              x21 * y14 + x22 * y24 + x23 * y34 + x24 * y44,
                x31 * y14 + x32 * y24 + x33 * y34 + x34 * y44,
                  x41 * y14 + x42 * y24 + x43 * y34 + x44 * y44]

-- | Matrix multiplication, assuming a and b are affine: a * b
mulAffine :: Mat4 -> Mat4 -> Mat4
mulAffine (Mat [x11, x12, x13, x14, x21, x22, x23, x24, x31, x32, x33, x34, x41, x42, x43, x44])
          (Mat [y11, y12, y13, y14, y21, y22, y23, y24, y31, y32, y33, y34, y41, y42, y43, y44]) =
     Mat [x11 * y11 + x12 * y21 + x13 * y31,
              x21 * y11 + x22 * y21 + x23 * y31,
                x31 * y11 + x32 * y21 + x33 * y31,
                  0,
           x11 * y12 + x12 * y22 + x13 * y32,
              x21 * y12 + x22 * y22 + x23 * y32,
                x31 * y12 + x32 * y22 + x33 * y32,
                  0,
            x11 * y13 + x12 * y23 + x13 * y33,
              x21 * y13 + x22 * y23 + x23 * y33,
                x31 * y13 + x32 * y23 + x33 * y33,
                  0,
            x11 * y14 + x12 * y24 + x13 * y34 + x14,
              x21 * y14 + x22 * y24 + x23 * y34 + x24,
                x31 * y14 + x32 * y24 + x33 * y34 + x34,
                  1]

-- | Creates a transformation matrix for rotation in radians about the 3-element V.Vector axis.
makeRotate :: Number -> Vec3N -> Mat4
makeRotate angle axis =
  case V.normalize axis of
    V.Vec [x,y,z] ->
      let c = cos angle
          c1 = 1-c
          s = sin angle
      in Mat [x*x*c1+c,y*x*c1+z*s,z*x*c1-y*s,0,
              x*y*c1-z*s,y*y*c1+c,y*z*c1+x*s,0,
              x*z*c1+y*s,y*z*c1-x*s,z*z*c1+c,0,
              0,0,0,1]
-}


foreign import rotateST """
  function rotateST(angle) {
      return function(a){
        return function(arr){
           return function(){
             var l      = Math.sqrt (a[0]*a[0] + a[1]*a[1] + a[2]*a[2]);
             var im     = 1.0 / l;
             var x      = a[0] * im;
             var y      = a[1] * im;
             var z      = a[2] * im;
             var c      = Math.cos (angle);
             var c1     = 1-c
             var s      = Math.sin (angle);
             var xs     = x*s;
             var ys     = y*s;
             var zs     = z*s;
             var xyc1   = x*y*c1;
             var xzc1   = x*z*c1;
             var yzc1   = y*z*c1;
             var t11    = x*x*c1+c;
             var t21    = xyc1+zs;
             var t31    = xzc1-ys;
             var t12    = xyc1-zs;
             var t22    = y*y*c1+c;
             var t32    = yzc1+xs;
             var t13    = xzc1+ys;
             var t23    = yzc1-xs;
             var t33    = z*z*c1+c;

             var m  = arr.slice();
             for (var i=0; i<4; i++){
                 = m[i] * t11 + m[i+4] * t21 + m[i+8] * t31;
                arr[i+4] = m[i] * t12 + m[i+4] * t22 + m[i+8] * t32;
                arr[i+8] = m[i] * t13 + m[i+4] * t23 + m[i+8] * t33;
             };
           };
        };
      };
  }""" :: forall h r. Number -> Vec3N -> STMat4 h -> Eff (st :: ST h | r) Unit

-- generic type was :: forall h r. Number -> [Number] -> STArray h Number -> Eff (st :: ST h | r) Unit

foreign import translateST """
  function translateST(a) {
      return function(m){
           return function(){
             for (var i=0; i<4; i++){
                m[i+12] += m[i] * a[0] + m[i+4] * a[1] + m[i+8] * a[2];
             };
           };
      };
  }""" :: forall h r. Vec3N -> STMat4 h -> Eff (st :: ST h | r) Unit

-- generic type was :: forall h r. [Number] -> STArray h Number -> Eff (st :: ST h | r) Unit

foreign import scaleST3 """
    function scaleST3(x) {
        return function(y){
            return function(z){
                return function(m){
                    return function(){
                        m[0] = m[0]*x;
                        m[1] = m[1]*x;
                        m[2] = m[2]*x;
                        m[3] = m[3]*x;

                        m[4] = m[4]*y;
                        m[5] = m[5]*y;
                        m[6] = m[6]*y;
                        m[7] = m[7]*y;

                        m[8] = m[8]*z;
                        m[9] = m[9]*z;
                        m[10] = m[10]*z;
                        m[11] = m[11]*z;

                        };
                    };
                };
            };
        }
""" :: forall h r. Number -> Number -> Number -> STMat4 h -> Eff (st :: ST h | r) Unit

{-
-- | Creates a transformation matrix for scaling by 3 scalar values, one for
-- each of the x, y, and z directions.
makeScale3 :: Number -> Number -> Number -> Mat4
makeScale3 x y z = Mat [x,0,0,0,
                          0,y,0,0,
                          0,0,z,0,
                          0,0,0,1]

-- | Creates a transformation matrix for scaling each of the x, y, and z axes by
-- the amount given in the corresponding element of the 3-element V.Vector.
makeScale :: Vec3N -> Mat4
makeScale (V.Vec [x,y,z]) = makeScale3 x y z

-- | Concatenates a scaling to the given matrix.
scale3 :: Number -> Number -> Number -> Mat4 -> Mat4
scale3 x y z (Mat [x11, x12, x13, x14, x21, x22, x23, x24, x31, x32, x33, x34, x41, x42, x43, x44]) =
  Mat [x11*x, x12*x, x13*x, x14*x,
        x21*y, x22*y, x23*y, x24*y,
        x31*z, x32*z, x33*z, x34*z,
        x41, x42, x43, x44]

-- | Concatenates a scaling to the given matrix.
scale :: Vec3N -> Mat4 -> Mat4
scale (V.Vec [x,y,z]) = scale3 x y z

-- | Creates a transformation matrix for translating by 3 scalar values, one for
-- each of the x, y, and z directions.
makeTranslate3 :: Number -> Number -> Number -> Mat4
makeTranslate3 x y z = Mat [1,0,0,0,
                              0,1,0,0,
                              0,0,1,0,
                              x,y,z,1]

-- | Creates a transformation matrix for translating each of the x, y, and z
-- axes by the amount given in the corresponding element of the 3-element V.Vector.
makeTranslate :: Vec3N -> Mat4
makeTranslate (V.Vec [x,y,z]) = makeTranslate3 x y z



-- | Creates a transformation matrix for a camera.
-- Parameters:
--  * eye - The location of the camera
--  * center - The location of the focused object
--  * up - The "up" direction according to the camera
makeLookAt :: Vec3N -> Vec3N -> Vec3N -> Mat4
makeLookAt eye@(V.Vec [e0,e1,e2]) center up =
  case V.direction eye center of
    z@V.Vec [z0,z1,z2] ->
      case V.normalize (V3.cross up z) of
        x@V.Vec [x0,x1,x2] ->
          case V.normalize (V3.cross z x) of
            y@V.Vec [y0,y1,y2] ->
              let m1 = Mat [x0,y0,z0,0,
                             x1,y1,z1,0,
                             x2,y2,z2,0,
                             0,0,0,1]
                  m2 = Mat [1,0,0,0,
                             0,1,0,0,
                             0,0,1,0,
                             (-e0),(-e1),(-e2),1]
                in mul m1 m2

-- | Creates a transform from a basis consisting of 3 linearly independent V.Vectors.
makeBasis :: Vec3N -> Vec3N -> Vec3N -> Mat4
makeBasis (V.Vec [x0,x1,x2]) (V.Vec [y0,y1,y2]) (V.Vec [z0,z1,z2])=
  Mat [x0,x1,x2,0,
        y0,y1,y2,0,
        z0,z1,z2,0,
        0,0,0,1]
-}