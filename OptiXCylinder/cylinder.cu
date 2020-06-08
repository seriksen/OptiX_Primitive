#include <optix.h>
#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>
#include <optixu/optixu_aabb_namespace.h>

using namespace optix;

// Communication Variables
rtDeclareVariable(float3, cylinder_p, , );
rtDeclareVariable(float3, cylinder_q, , );
rtDeclareVariable(float4, cylinder_r, , );
rtDeclareVariable(optix::Ray, ray, rtCurrentRay, );
rtDeclareVariable(float3, texcoord, attribute texcoord, );
rtDeclareVariable(float3, geometric_normal, attribute geometric_normal, );
rtDeclareVariable(float3, shading_normal, attribute shading_normal, );

//static __device__ float3 cylindernormal(float t) //float t, float3 t0, float3 t1)
//{
//  return t;
  //float3 neg = make_float3(t==t0.x?1:0, t==t0.y?1:0, t==t0.z?1:0);
  //float3 pos = make_float3(t==t1.x?1:0, t==t1.y?1:0, t==t1.z?1:0);
  //return pos-neg;
//}

/*
 * Cylinder Intersection
 * NOTE: Follows intersection maths described in RTCD - Christer Ericson so
 * cylinder origin is at P.
 *
 * Essentially it's comparing the cylinder frame to the ray frame
 *
 * Define cylinder as P,Q,r                Define ray as A,B
 * <--r-|
 * +----Q----*                          A -------------- B
 * |         |
 * |         X
 * |         |
 * +----P----+
 *
 * If X is a point on the cylinder surface then
 * (v - w) . (v - w) - r2 = 0 (eq 1)
 * where;
 * v = X - P, d = Q - P, w = ((v.d)/(d.d)) . d
 *
 * Intersection
 *       +---------+             L(t) = A + t(B-A)
 *       |         |
 *   A---|---------|---B
 *       |         |
 *       +---------+
 * Intersection defined as L(t) = X so solve for t
 *
 * After some rearranging we eq 1 becomes
 * (n.n - (n.d)^2 / (d.d))t^2 + 2(m.n - (n.d)(m.d)/(d.d))t
 *  + m.m - (m.d)^2 / (d.d) - r^2 = 0
 * Where m = A - P and n = B - A (from v = L(t) - P)
 *
 * This is what needs to be solved
 *
 * Alternatively can be written as
 * ((d.d)(n.n) - (n.d)^2)t^2 + 2((d.d)(m.n) - (n.d)(m.d))t
 *  + (d.d)((m.m)- r^2) - (m.d)^2 = 0
 *
 * So a quadratic in the form of at^2 + 2bt + c = 0
 * where
 *      a = (d.d)(n.n) - (n.d)^2         = (d x n).(d x n)
 *      b = (d.d)(m.n) - (n.d)(m.d)      = (d x m).(d x n)
 *      c = (d.d)((m.m) - r^2) - (m.d)^2 = (d x m).(d x m) - (d.d)r^2
 *
 * Key points
 * If a = 0 -> d and n are parallel
 * a > 0
 * If c < 0 -> intersect is inside cylinder surface
 * If c > 0 -> intersect is outside cylinder surface
 *
 * Solve using standard formula: t = (-b +/- sqrt(b^2 - ac)) / (a)
 *
 * Case: b^2 - ac < 0
 *  - No roots
 *  - No intersection
 *
 * Case: B^2 - ac > 0
 *  - Two roots
 *  - root1 (smaller) = value where line enters cylinder
 *  - root2 (larger) = value where line exists cylinder
 *
 * Ray could intersect with endcaps (P and Q)
 *
 * Case: P-endcap
 *  - ray is outside plane P if;
 *      (L(t) - P).d < 0 -> (m.d) + t(n.d) < 0
 *      So don't need to test against P in this case
 *  - ray is outside cylinder if;
 *    n.d <= 0
 *    -> L(t) points away from P
 *    So don't need to test against P in this case
 *  - Only need to test against P if;
 *    n.d > 0
 *    Need to test against P
 *  - Test against P
 *     (X - P).d = 0 -> t = - (m.d) / n.d
 *     (L(t) - P).(L(t) - P) <= r^2
 *
 * Case: Q-endcap
 *  - ray is outside plane Q if;
 *    (L(t) - P).d > d.d -> (m.d) + t(n.d) > d.d
 *    So don't need to test against Q
 *  - Only need to test against Q of;
 *    n.d < 0
 *  - Test against Q
 *    (X - Q).d = 0 -> t = ((d.d) - (m.d))/(n.d)
 *    (L(t) - Q).(L(t) - Q) <= r^2
 *
 * TODO: Add graphical representation of d,n,m,etc...
 *
 * intersection implementation
 * - 2 checks
 *   - endcaps
 *   - infinite cylinder
 * - endcaps
 *   - check for intersection with P and Q if ray origin is outside cylinder
 *
 */
RT_PROGRAM void intersect(int) {
  // Cylinder properties from RT variables
  float3 p = cylinder_p;
  float3 q = cylinder_q;
  float r = cylinder_r.w;

  float3 d = make_float3(0.f,0.f,q.z - p.z); // cylinder z
  shading_normal = geometric_normal = make_float3(0.f,1.0f,0.f);
  rtReportIntersection(0);
  return;
  // Ray information
  float3 m = ray.origin - p; // ray origin relative to P
  float3 n = ray.direction;

  // Initial dot products
  // TODO: Move them all together
  float md = dot(m, d);
  float nd = dot(n, d);
  float dd = dot(d, d);

  //***************
  // Test Endcaps
  //***************

  // Below P
  if (md < 0.0f && md + nd < 0.0f)
    return;
  // Above Q
  if (md > dd && md + nd > dd)
    return;

  // More dot products
  float nn = dot(n,n);
  float mn = dot(m,n);
  float mm = dot(m,m);
  float a = dd * nn - nd * nd;
  float c = dd * (mm - r*r) - md * md;

  // Also define t
  float t;

  // If a is parallel to cylinder
  if (fabs(a) < 1e-6f) {

    // outside of cylinder
    if (c > 0.f) return;

    // If still in, means ray intersects

    // Intersects P endcap
    if (md < 0.f) {
      t = - mn / nn;
      if (rtPotentialIntersection(t)) {
        shading_normal = geometric_normal = -normalize(d);
        rtReportIntersection(0);
      }
    }
    // Intersect Q endcap
    else if (md > dd) {
      t = (nd - mn) / nn;
      if (rtPotentialIntersection(t)) {
        shading_normal = geometric_normal = normalize(d);
        rtReportIntersection(0);
      }
    }
    // Ray origin is inside cylinder
    else {
      // going to say that the ray counts as a miss for now
      //t = 0.f;
      return;
    }
  }

  //************************
  // Test Infinite Cylinder
  //************************

  // Define some more things
  float b = dd * mn - nd * md;
  float disc = b*b - a*c;

  // Has no roots
  if (disc < 0.f) return;


  t = (-b - sqrtf(disc)) / a;
  float radius_check;
  // Intersection is outside segment
  if (t < 0.f || t > 1.0f) return;

  // Intersection on P side
  if (md + t * nd < 0.f) {
    // Ray is going away from endcap
    if (nd <= 0.f) return;

    t = -md/nd; // P endcap
    radius_check = mm -r*r + t * (2.f * mn + t*nn);
    if (radius_check <= 0.f) {
      if (rtPotentialIntersection(t)) {
        shading_normal = geometric_normal = -normalize(d);
        rtReportIntersection(0);
      }
    }
  }
  // Intersection on Q side
  else if (md + t * nd > dd) {
    // Ray is going away from endcap
    if (nd >= 0.f) return;

    t = (dd - md) / nd; // Q endcap
    radius_check = mm - r*r + t * (2.f * (mn - nd) + t * nn);
    if (radius_check <= 0.f) {
      if (rtPotentialIntersection(t)) {
        shading_normal = geometric_normal = normalize(d);
      }
    }
  }
  // ray intersects cylinder between the end caps
  else {
      if (rtPotentialIntersection(t)) {
        shading_normal = geometric_normal = normalize(d);
      }
  }

  // FIXME: add second root
  return;

}

RT_PROGRAM void bounds (int, float result[6])
{
  optix::Aabb* aabb = (optix::Aabb*)result;
  aabb->set(cylinder_p, cylinder_q);
}