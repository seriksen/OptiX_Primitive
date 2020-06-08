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
  float3 position = cylinder_p;  // 0,0,-169.  <-- P: point on axis at base of cylinder

  float zmin = cylinder_p.z ;  // using bbox z-range
  float zmax = cylinder_q.z ;

  float clipped_sizeZ = zmax - zmin ;
  float radius = cylinder_r.w ;


  //rtPrintf("intersect_ztubs position %10.4f %10.4f %10.4f \n", position.x, position.y, position.z );
  //rtPrintf("intersect_ztubs flags %d PCAP %d QCAP %d \n", flags, PCAP, QCAP);

  float3 m = ray.origin - position ;                  // ray origin in cylinder P-frame
  float3 n = ray.direction ;
  float3 d = make_float3(0.f, 0.f, clipped_sizeZ );   // cylinder axis

  float rr = radius*radius ;
  float3 dnorm = normalize(d);


  float mm = dot(m, m) ;
  float nn = dot(n, n) ;
  float dd = dot(d, d) ;
  float nd = dot(n, d) ;
  float md = dot(m, d) ;
  float mn = dot(m, n) ;
  float k = mm - rr ;

  // quadratic coefficients of t,     a tt + 2b t + c = 0
  float a = dd*nn - nd*nd ;
  float b = dd*mn - nd*md ;
  float c = dd*k - md*md ;

  float disc = b*b-a*c;

  // axial ray endcap handling
  if(fabs(a) < 1e-6f)
  {
    if(c > 0.f) return ;    // ray starts and ends outside cylinder
    if(md < 0.f)    // ray origin on P side
    {
      float t = -mn/nn ;  // P endcap
      if( rtPotentialIntersection(t) )
      {
        shading_normal = geometric_normal = -dnorm  ;
        rtReportIntersection(0);
      }
    }
    else if(md > dd) // ray origin on Q side
    {
      float t = (nd - mn)/nn ;  // Q endcap
      if( rtPotentialIntersection(t) )
      {
        shading_normal = geometric_normal = dnorm ;
        rtReportIntersection(0);
      }
    }
    else    // md 0->dd, ray origin inside
    {
      if( nd > 0.f) // ray along +d
      {
        float t = -mn/nn ;    // P endcap from inside
        if( rtPotentialIntersection(t) )
        {
          shading_normal = geometric_normal = dnorm  ;
          rtReportIntersection(0);
        }
      }
      else  // ray along -d
      {
        float t = (nd - mn)/nn ;  // Q endcap from inside
        if( rtPotentialIntersection(t) )
        {
          shading_normal = geometric_normal = -dnorm ;
          rtReportIntersection(0);
        }
      }
    }
    return ;   // hmm
  }

  if(disc > 0.0f)  // intersection with the infinite cylinder
  {
    float sdisc = sqrtf(disc);

    float root1 = (-b - sdisc)/a;

    // m:ray.origin-position
    // n:ray.direction

    float ad1 = md + root1*nd ;        // axial coord of intersection point (* sizeZ)
    float3 P1 = ray.origin + root1*ray.direction ;

    if( ad1 > 0.f && ad1 < dd )  // intersection inside cylinder range
    {
      if( rtPotentialIntersection(root1) )
      {
        float3 N  = (P1 - position)/radius  ;
        N.z = 0.f ;

        //rtPrintf("intersect_ztubs r %10.4f disc %10.4f sdisc %10.4f root1 %10.4f P %10.4f %10.4f %10.4f N %10.4f %10.4f \n",
        //    radius, disc, sdisc, root1, P1.x, P1.y, P1.z, N.x, N.y );

        shading_normal = geometric_normal = normalize(N) ;
        rtReportIntersection(0);
      }
    }
    else if( ad1 < 0.f ) //  intersection outside cylinder on P side
    {
      if( nd <= 0.f ) return ; // ray direction away from endcap
      float t = -md/nd ;   // P endcap
      float checkr = k + t*(2.f*mn + t*nn) ; // bracket typo in book 2*t*t makes no sense
      if ( checkr < 0.f )
      {
        if( rtPotentialIntersection(t) )
        {
          shading_normal = geometric_normal = -dnorm  ;
          rtReportIntersection(0);
        }
      }
    }
    else if( ad1 > dd  ) //  intersection outside cylinder on Q side
    {
      if( nd >= 0.f ) return ; // ray direction away from endcap
      float t = (dd-md)/nd ;   // Q endcap
      float checkr = k + dd - 2.0f*md + t*(2.f*(mn-nd)+t*nn) ;
      if ( checkr < 0.f )
      {
        if( rtPotentialIntersection(t) )
        {
          shading_normal = geometric_normal = dnorm  ;
          rtReportIntersection(0);
        }
      }
    }


    float root2 = (-b + sdisc)/a;     // far root : means are inside (always?)
    float ad2 = md + root2*nd ;        // axial coord of far intersection point
    float3 P2 = ray.origin + root2*ray.direction ;


    if( ad2 > 0.f && ad2 < dd )  // intersection from inside against wall
    {
      if( rtPotentialIntersection(root2) )
      {
        float3 N  = (P2 - position)/radius  ;
        N.z = 0.f ;

        shading_normal = geometric_normal = -normalize(N) ;
        rtReportIntersection(0);
      }
    }
    else if( ad2 < 0.f ) //  intersection from inside to P endcap
    {
      float t = -md/nd ;   // P endcap
      float checkr = k + t*(2.f*mn + t*nn) ; // bracket typo in book 2*t*t makes no sense
      if ( checkr < 0.f )
      {
        if( rtPotentialIntersection(t) )
        {
          shading_normal = geometric_normal = dnorm  ;
          rtReportIntersection(0);
        }
      }
    }
    else if( ad2 > dd ) //  intersection from inside to Q endcap
    {
      float t = (dd-md)/nd ;   // Q endcap
      float checkr = k + dd - 2.0f*md + t*(2.f*(mn-nd)+t*nn) ;
      if ( checkr < 0.f )
      {
        if( rtPotentialIntersection(t) )
        {
          shading_normal = geometric_normal = -dnorm  ;
          rtReportIntersection(0);
        }
      }
    }
  }
}

/*
  float3 p = cylinder_p;
  float3 q = cylinder_q;
  float r = cylinder_r.w;

  float3 d = make_float3(0.f,0.f,q.z - p.z); // cylinder z
  if (rtPotentialIntersection(0.01f)) {
    shading_normal = geometric_normal = make_float3(0.f, 1.0f, 0.f);
    rtReportIntersection(0);
  }
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
*/
RT_PROGRAM void bounds (int, float result[6])
{
  optix::Aabb* aabb = (optix::Aabb*)result;
  aabb->set(cylinder_p, cylinder_q);
}
