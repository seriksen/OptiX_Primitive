/*
 * Copyright (c) 2019 Opticks Team. All Rights Reserved.
 *
 * This file is part of Opticks
 * (see https://bitbucket.org/simoncblyth/opticks).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <cstdlib>
#include <cstring>
#include <fstream>
#include <optix_world.h>
#include <optixu/optixpp_namespace.h>
#include <sstream>

#include <glm/glm.hpp>
#include <glm/gtx/transform.hpp>

// Composition::getEyeUVW and examples/UseGeometryShader:getMVP
void getEyeUVW(const glm::vec4 &ce, const unsigned width, const unsigned height,
               glm::vec3 &eye, glm::vec3 &U, glm::vec3 &V, glm::vec3 &W) {
  glm::vec3 tr(ce.x, ce.y, ce.z); // ce is center-extent of model
  glm::vec3 sc(ce.w);
  glm::vec3 isc(1.f / ce.w);
  // model frame unit coordinates from/to world
  glm::mat4 model2world = glm::scale(glm::translate(glm::mat4(1.0), tr), sc);
  // glm::mat4 world2model = glm::translate( glm::scale(glm::mat4(1.0), isc),
  // -tr);

  // View::getTransforms
  glm::vec4 eye_m(0.00001f, 0.00001f, 2.f, 1.f); //  viewpoint in unit model frame
                                         // eye_m(-1.f, -1.f, 1.f, 1.f); //  viewpoint in unit model frame
  glm::vec4 look_m(0.f, 0.f, 0.f, 1.f);
  glm::vec4 up_m(0.f, 0.f, 1.f, 1.f);
  glm::vec4 gze_m(look_m - eye_m);

  const glm::mat4 &m2w = model2world;
  glm::vec3 eye_ = glm::vec3(m2w * eye_m);
  // glm::vec3 look = glm::vec3( m2w * look_m ) ;
  glm::vec3 up = glm::vec3(m2w * up_m);
  glm::vec3 gaze = glm::vec3(m2w * gze_m);

  glm::vec3 forward_ax = glm::normalize(gaze);
  glm::vec3 right_ax = glm::normalize(glm::cross(forward_ax, up));
  glm::vec3 top_ax = glm::normalize(glm::cross(right_ax, forward_ax));

  float aspect = float(width) / float(height);
  float tanYfov = 1.f; // reciprocal of camera zoom
  float gazelength = glm::length(gaze);
  float v_half_height = gazelength * tanYfov;
  float u_half_width = v_half_height * aspect;

  U = right_ax * u_half_width;
  V = top_ax * v_half_height;
  W = forward_ax * gazelength;
  eye = eye_;
}

const char *PTXPath(const char *install_prefix, const char *cmake_target,
                    const char *cu_stem, const char *cu_ext = ".cu") {
  std::stringstream ss;
  ss << install_prefix << "/ptx/" << cmake_target << "_generated_" << cu_stem
     << cu_ext << ".ptx";
  std::string path = ss.str();
  return strdup(path.c_str());
}

const char *PPMPath(const char *install_prefix, const char *stem,
                    const char *ext = ".ppm") {
  std::stringstream ss;
  ss << install_prefix << "/ppm/" << stem << ext;
  std::string path = ss.str();
  return strdup(path.c_str());
}

void SPPM_write(const char *filename, const unsigned char *image, int width,
                int height, int ncomp, bool yflip) {
  FILE *fp;
  fp = fopen(filename, "wb");

  fprintf(fp, "P6\n%d %d\n%d\n", width, height, 255);

  unsigned size = height * width * 3;
  unsigned char *data = new unsigned char[size];

  for (int h = 0; h < height; h++) // flip vertically
  {
    int y = yflip ? height - 1 - h : h;

    for (int x = 0; x < width; ++x) {
      *(data + (y * width + x) * 3 + 0) = image[(h * width + x) * ncomp + 0];
      *(data + (y * width + x) * 3 + 1) = image[(h * width + x) * ncomp + 1];
      *(data + (y * width + x) * 3 + 2) = image[(h * width + x) * ncomp + 2];
    }
  }
  fwrite(data, sizeof(unsigned char) * size, 1, fp);
  fclose(fp);
  std::cout << "Wrote file (unsigned char*) " << filename << std::endl;
  delete[] data;
}

optix::Context createContext(unsigned entry_point_index,
                             const char* ptx,
                             const char* raygen,
                             const char* miss)
{
  optix::Context context = optix::Context::create();

  // Only need one type of array as only care about radiance
  // Only need radiance ray
  context->setRayTypeCount(1);

  context->setPrintEnabled(true);
  // context->setPrintLaunchIndex(5,0,0);
  context->setPrintBufferSize(4096);
  context->setEntryPointCount(1);

  // Get Ray Generation from PTX file
  // See raygen in OptiXBox.cu
  context->setRayGenerationProgram(
      entry_point_index, context->createProgramFromPTXFile(ptx, raygen));

  // Get Miss from PTX file
  // See miss in OptiXBox.cu
  context->setMissProgram(entry_point_index,
                          context->createProgramFromPTXFile(ptx, miss));

  return context;

}

optix::Material createMaterial(optix::Context context,
                               const char  *ptx,
                               const char *closest_hit,
                               unsigned entry_point_index
)
{
  optix::Material mat = context->createMaterial();
  mat->setClosestHitProgram(
      entry_point_index,
      context->createProgramFromPTXFile(ptx, closest_hit));

  return mat;
}


optix::GeometryInstance createCylinder(optix::Context context,
                                       optix::Material material,
                                       glm::vec4 ce,
                                       const char *ptx,
                                       const char* primitive_ptx)
{
  optix::Geometry geometry;
  assert(geometry.get() == NULL);

  geometry = context->createGeometry();
  assert(geometry.get() != NULL);

  // The box geometry only has one primitive = box.cu
  geometry->setPrimitiveCount(1u);

  // Get box primitive bounds from PTX file
  // See box_bounds in box.cu
  geometry->setBoundingBoxProgram(
      context->createProgramFromPTXFile(primitive_ptx, "bounds"));

  // Get box primitive intersection from PTX file
  // See box_intersect in box.cu
  geometry->setIntersectionProgram(
      context->createProgramFromPTXFile(primitive_ptx, "intersect"));

  // Set box size
  float sz = ce.w;
  geometry["disc_shape"]->setFloat(0.f, 0.f, 0.f, 0.5f);
  geometry["disc_min"]->setFloat(-0.5f,-0.5f,-0.5f);
  geometry["disc_max"]->setFloat(0.5f,0.5f,0.5f);
  // Put it all together
  optix::GeometryInstance gi =
      context->createGeometryInstance(geometry, &material, &material + 1);

  return gi;
}


int main(int argc, char **argv) {

  // Set/Get names
  const char *name = "TitaniumPlate";
  const char *primitive = "discwithholes";
  const char *prefix = getenv("PREFIX");
  assert(prefix && "expecting PREFIX envvar pointing to writable directory");

  const char *cmake_target = name;

  // Set image size
  unsigned width = 1024u;
  unsigned height = 768;

  glm::vec4 ce(0., 0., 0., 0.5);

  glm::vec3 eye;
  glm::vec3 U;
  glm::vec3 V;
  glm::vec3 W;
  getEyeUVW(ce, width, height, eye, U, V, W);

  unsigned entry_point_index = 0u;
  const char *ptx = PTXPath(prefix, cmake_target, name);
  const char *primitive_ptx = PTXPath(prefix, cmake_target, primitive);

  optix::Context context = createContext(entry_point_index, ptx, "raygen",
                                         "miss");

  optix::Material material = createMaterial(context, ptx,
                                            "closest_hit_radiance0",
                                            entry_point_index);

  optix::GeometryInstance gi = createCylinder(context, material, ce, ptx,
                                              primitive_ptx);


  optix::GeometryGroup gg = context->createGeometryGroup();
  gg->setChildCount(1);
  gg->setChild(0, gi);
  gg->setAcceleration(context->createAcceleration("Trbvh"));

  context["top_object"]->set(gg);

  float near = 0.1f;
  float scene_epsilon = near;

  context["scene_epsilon"]->setFloat(scene_epsilon);
  context["eye"]->setFloat(eye.x, eye.y, eye.z);
  context["U"]->setFloat(U.x, U.y, U.z);
  context["V"]->setFloat(V.x, V.y, V.z);
  context["W"]->setFloat(W.x, W.y, W.z);
  context["radiance_ray_type"]->setUint(0u);

  optix::Buffer output_buffer = context->createBuffer(
      RT_BUFFER_OUTPUT, RT_FORMAT_UNSIGNED_BYTE4, width, height);
  context["output_buffer"]->set(output_buffer);

  context->launch(entry_point_index, width, height);

  // ------------  \\
  // Write Out PPM \\
  // ------------- \\
  //
  const char *path = PPMPath(prefix, name);
  std::cout << "write " << path << std::endl;

  bool yflip = true;
  int ncomp = 4;
  void *ptr = output_buffer->map();
  SPPM_write(path, (unsigned char *)ptr, width, height, ncomp, yflip);
  output_buffer->unmap();

  return 0;
}
