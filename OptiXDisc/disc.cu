#include <optix.h>
#include <optixu/optixu_aabb_namespace.h>
#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

using namespace optix;

// Communication Variables
rtDeclareVariable(float3, cylinder_p, , );
rtDeclareVariable(float3, cylinder_q, , );
rtDeclareVariable(float4, cylinder_r, , );
rtDeclareVariable(float3, cylinder_min, , );
rtDeclareVariable(float3, cylinder_max, , );
rtDeclareVariable(optix::Ray, ray, rtCurrentRay, );
rtDeclareVariable(float3, texcoord, attribute texcoord, );
rtDeclareVariable(float3, geometric_normal, attribute geometric_normal, );
rtDeclareVariable(float3, shading_normal, attribute shading_normal, );


RT_PROGRAM void intersect(int) {

  float z1 = 0.01f;
  float z2 = -0.01f;
  float zc = (z1 + z2) / 2.f;
  float radius = 0.1f;
  float inner = 0.01; // ? what is this?
  float dz = (z2 - z1) / 2.f;
  float3 center = make_float3(0.f,0.f,0.f);

  float3 m = ray.origin - center;
  float3 n = ray.direction;
  float3 d = make_float3(0.f,0.f,1.f);

  float rr = radius*radius;
  float ii = inner * inner;

  float mm = dot(m, m) ;
  float nn = dot(n, n) ;
  float nd = dot(n, d) ;   // >0 : ray direction in same hemi as normal
  float md = dot(m, d) ;
  float mn = dot(m, n) ;

  float t_min = 0.f;

  float t_center = -md/nd ;
  float rsq = t_center*(2.f*mn + t_center*nn) + mm  ;   // ( m + tn).(m + tn)

  float t_delta  = nd < 0.f ? -zdelta/nd : zdelta/nd ;    // <-- pragmatic make t_delta +ve

  float root1 = t_center - t_delta ;
  float root2 = t_center + t_delta ;   // root2 > root1

  float t_cand = ( rsq < rr && rsq > ii ) ? ( root1 > t_min ? root1 : root2 ) : t_min ;

  float side = md + t_cand*nd ;

  bool valid_isect = t_cand > t_min ;
  if(valid_isect) {
    if( rtPotentialIntersection( t_cand ) ) {
      shading_normal = geometric_normal = normalize(d);
      rtReportIntersection(0);
        }
  }
  return;
}

RT_PROGRAM void bounds(int, float result[6]) {
  optix::Aabb *aabb = (optix::Aabb *)result;
  aabb->set(cylinder_min, cylinder_max);
}
