#include <optix.h>
#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>
#include <optixu/optixu_aabb_namespace.h>

using namespace optix;

// Communication Variables
rtDeclareVariable(float3, cylinder_min, , );
rtDeclareVariable(float3, cylinder_max, , );
rtDeclareVariable(float3, cylinder_r, , );
rtDeclareVariable(optix::Ray, ray, rtCurrentRay, );
rtDeclareVariable(float3, texcoord, attribute texcoord, );
rtDeclareVariable(float3, geometric_normal, attribute geometric_normal, );
rtDeclareVariable(float3, shading_normal, attribute shading_normal, );

static __device__ float3 cylindernormal(float t, float3 t0, float3 t1)
{
  float3 neg = make_float3(t==t0.x?1:0, t==t0.y?1:0, t==t0.z?1:0);
  float3 pos = make_float3(t==t1.x?1:0, t==t1.y?1:0, t==t1.z?1:0);
  return pos-neg;
}

// cylinder intersection
// Following intersection maths described ub RTCD - Christer Ericson
// Define
/**
 * @brief Calculate if Cylinder intersection
 * NOTE: Follows intersection maths described in RTCD - Christer Ericson so
 * cylinder origin is at P.
 *
 *
 * Define cylinder as P,Q,r                Define ray as A,B
 * <--r-|
 * +----Q----*                          A -------------- B
 * |         |
 * |         |
 * +----P----+
 *
 * If X is a point on the cylinder surface then
 * (v - w) . (v - w) - r2 = 0
 * where;
 * v = X - P, d = Q - P, w = ((v.d)/(d.d)) . d
 *
 * Intersection
 *       +---------+             L(t) = A + t(B-A)
 *       |         |
 *   A---|---------|---B
 *       |         |
 *       +---------+
 * Intersection defined as L(t) = X
 *
 */
RT_PROGRAM void intersect(int)
{
  float3 d = float3(0.f, 0.f, 0.25f) / ray.direction; // unit length
  float3 m = ray.origin - cylinder_min; // Relative to P
  float3 p = (cylinder_min - ray.origin)/ray.direction;
  float3 q = (cylinder_max - ray.origin)/ray.direction;
  float3 n = ray.direction;
  float r = cylinder_r.x;
  bool check_second = true;

  // Calculate variables
  float3 md = dot(m,d);
  float3 nd = dot(n,d);
  float3 dd = dot(d,d);
  float3 nn = dot(n,n);
  float3 mn = dot(m,n);
  float3 mm = dot(m,m);
  float a = dd * nn - nd * nd;
  float k = mm - r*r;
  float c = dd * k - md * md;

  // Test if fully outside endcaps of cylinder
  if (md < 0.0f && md + nd < 0.0f) {
    // Not in cylinder
    // Below P
    return;
  }
  else if (md > dd && md + nd > dd) {
    // Not in cylinder
    // Above P and Q
    return;
  }
  // Is within endcaps
  else if (fabs(a) < 1e-6f) {
    if (c > 0.f) {
      // Not in cyclinder
      // 'a' is outside cylinder
      return;
    }
    // Check if endcap intersect
    if (md < 0.f) {
      // Intersect with P
      t = -mn / nn;
    }
    else if (md > dd) {
      // Intersect with Q
      t = (nd - mn) / nn;
    }
    else {
      // 'a' is inside cylinder
      if (rtPotentialIntersection()) {
        shading_normal = geometric_normal = cylindernormal(m, p, q);
        if(rtReportIntersection(0)) {
          check_second = false;
        }
      }
    }

  }
}

RT_PROGRAM void bounds (int, float result[6])
{
  optix::Aabb* aabb = (optix::Aabb*)result;
  aabb->set(cylinder_min, cylinder_max);
}
