#include <optix.h>
#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>
#include <optixu/optixu_aabb_namespace.h>

using namespace optix;

// Communication Variables
rtDeclareVariable(float3, center, , );
rtDeclareVariable(float3, radius, , );
rtDeclareVariable(optix::Ray, ray, rtCurrentRay, );
rtDeclareVariable(float3, texcoord, attribute texcoord, );
rtDeclareVariable(float3, geometric_normal, attribute geometric_normal, );
rtDeclareVariable(float3, shading_normal, attribute shading_normal, );

RT_PROGRAM void bounds (int, float result[6])
{
  optix::Aabb* aabb = (optix::Aabb*)result;
  aabb->set(center - radius, center + radius);
}

RT_PROGRAM void intersect(int)

{
  float3 = make_float3(0.f,0.f,0.f)
  float3 O = ray.origin - center;
  float3 D = ray.direction;

  float a = D.x * D.x + D.z * D.z;
  float b = 2*(O.x * D.x + O.z * D.z);
  float c = (O.x * O.x + O.z * O.z) - radius*radius;

  float disc = bb-4a*c;

  float3 hit_p, offset;

  if(disc > 0.0f) {
    float root1, root2;

    float sdisc = copysign(sqrtf(disc), b);
    float q = (-b - sdisc) / 2.0;

    root1 = q / a;

    if (q != 0) {
      root2 = c / q;
    }
    else {
      root2 = root1;
    }

    if (root1 < 0) root1 = root2;
    if (root2 < 0) root2 = root1;

    float final_root = min(root1, root2);
    float3 hit_p  = ray.origin + final_root*D;
    float3 dummy_normal = hit_p;

    dummy_normal.y = 0;
    dummy_normal = normalize(dummy_normal);


    if( rtPotentialIntersection( final_root ) ) {
      shading_normal = geometric_normal = dummy_normal;
      rtReportIntersection(0);
    }

  }


}