// picogk_bridge.h
// Genolanx — Swift/Metal bridge to PicoGK native library (picogk.1.7.dylib)
//
// This header declares all 117 exported C functions from the PicoGK native library.
// Types and signatures derived from PicoGK__Interop.cs (C# P/Invoke declarations)
// and verified against nm -gU output of picogk.1.7.dylib (ARM64).
//
// IMPORTANT: All structs are LayoutKind.Sequential, Pack=1 compatible.
// Vector3 = 12 bytes (3 x float), NOT 16-byte aligned SIMD.
// bool = 1 byte (_Bool/C99 bool).

#pragma once

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// ---------------------------------------------------------------------------
// MARK: - Opaque Handle Type
// ---------------------------------------------------------------------------

typedef void* PKHandle;

// ---------------------------------------------------------------------------
// MARK: - Data Structures (C-compatible, matching C# Sequential Pack=1)
// ---------------------------------------------------------------------------

typedef struct __attribute__((packed)) {
    float x, y;
} PKVector2;

typedef struct __attribute__((packed)) {
    float x, y, z;
} PKVector3;

typedef struct __attribute__((packed)) {
    // Row-major order (matching System.Numerics.Matrix4x4)
    // M11, M12, M13, M14, M21, M22, ...
    float m[16];
} PKMatrix4x4;

typedef struct __attribute__((packed)) {
    int32_t a, b, c;
} PKTriangle;

typedef struct __attribute__((packed)) {
    int32_t x, y, z;
} PKCoord;

typedef struct __attribute__((packed)) {
    float r, g, b, a;
} PKColorFloat;

typedef struct __attribute__((packed)) {
    PKVector3 vecMin;
    PKVector3 vecMax;
} PKBBox3;

// ---------------------------------------------------------------------------
// MARK: - Callback Typedefs
// ---------------------------------------------------------------------------

// Info/logging callback from native library
typedef void (*PKInfoCallback)(const char* pszMessage, bool bFatalError);

// Viewer update callback — supplies camera matrices and scene state
typedef void (*PKUpdateCallback)(
    PKHandle    hViewer,
    const PKVector2*    pvecViewport,
    PKColorFloat*       pclrBackground,
    PKMatrix4x4*        pmatModelViewProjection,
    PKMatrix4x4*        pmatModelTransform,
    PKMatrix4x4*        pmatStatic,
    PKVector3*          pvecEyePosition,
    PKVector3*          pvecEyeStatic
);

// Keyboard input callback
typedef void (*PKKeyPressedCallback)(
    PKHandle hViewer,
    int32_t  iKey,
    int32_t  iScancode,
    int32_t  iAction,
    int32_t  iModifiers
);

// Mouse move callback
typedef void (*PKMouseMovedCallback)(
    PKHandle            hViewer,
    const PKVector2*    pvecMousePos
);

// Mouse button callback
typedef void (*PKMouseButtonCallback)(
    PKHandle            hViewer,
    int32_t             iButton,
    int32_t             iAction,
    int32_t             iModifiers,
    const PKVector2*    pvecMousePos
);

// Scroll wheel callback
typedef void (*PKScrollWheelCallback)(
    PKHandle            hViewer,
    const PKVector2*    pvecScrollWheel,
    const PKVector2*    pvecMousePos
);

// Window resize callback
typedef void (*PKWindowSizeCallback)(
    PKHandle            hViewer,
    const PKVector2*    pvecWindowSize
);

// Implicit signed distance function callback
typedef float (*PKImplicitDistanceCallback)(const PKVector3* pvecPosition);

// Scalar field traversal callback
typedef void (*PKScalarFieldTraverseCallback)(
    const PKVector3* pvecPosition,
    float            fValue
);

// Vector field traversal callback
typedef void (*PKVectorFieldTraverseCallback)(
    const PKVector3* pvecPosition,
    const PKVector3* pvecValue
);

// ---------------------------------------------------------------------------
// MARK: - Library Functions (7)
// ---------------------------------------------------------------------------

void Library_Init(float fVoxelSizeMM);
void Library_Destroy(void);
void Library_GetName(char* pszBuffer);
void Library_GetVersion(char* pszBuffer);
void Library_GetBuildInfo(char* pszBuffer);
void Library_VoxelsToMm(const PKVector3* pvecVoxelCoord, PKVector3* pvecMmCoord);
void Library_MmToVoxels(const PKVector3* pvecMmCoord, PKVector3* pvecVoxelCoord);

// ---------------------------------------------------------------------------
// MARK: - Mesh Functions (12)
// ---------------------------------------------------------------------------

PKHandle Mesh_hCreate(void);
PKHandle Mesh_hCreateFromVoxels(PKHandle hVoxels);
bool     Mesh_bIsValid(PKHandle hMesh);
void     Mesh_Destroy(PKHandle hMesh);
int32_t  Mesh_nAddVertex(PKHandle hMesh, const PKVector3* pvecVertex);
int32_t  Mesh_nVertexCount(PKHandle hMesh);
void     Mesh_GetVertex(PKHandle hMesh, int32_t nIndex, PKVector3* pvecVertex);
int32_t  Mesh_nAddTriangle(PKHandle hMesh, const PKTriangle* ptTriangle);
int32_t  Mesh_nTriangleCount(PKHandle hMesh);
void     Mesh_GetTriangle(PKHandle hMesh, int32_t nIndex, PKTriangle* ptTriangle);
void     Mesh_GetTriangleV(PKHandle hMesh, int32_t nIndex,
                           PKVector3* pvecA, PKVector3* pvecB, PKVector3* pvecC);
void     Mesh_GetBoundingBox(PKHandle hMesh, PKBBox3* poBBox);

// ---------------------------------------------------------------------------
// MARK: - Lattice Functions (5)
// ---------------------------------------------------------------------------

PKHandle Lattice_hCreate(void);
bool     Lattice_bIsValid(PKHandle hLattice);
void     Lattice_Destroy(PKHandle hLattice);
void     Lattice_AddSphere(PKHandle hLattice,
                           const PKVector3* pvecCenter,
                           float fRadius);
void     Lattice_AddBeam(PKHandle hLattice,
                         const PKVector3* pvecA,
                         const PKVector3* pvecB,
                         float fRadiusA,
                         float fRadiusB,
                         bool bRoundCap);

// ---------------------------------------------------------------------------
// MARK: - Voxels Functions (22 — confirmed by nm)
// ---------------------------------------------------------------------------

PKHandle Voxels_hCreate(void);
PKHandle Voxels_hCreateCopy(PKHandle hSource);
bool     Voxels_bIsValid(PKHandle hVoxels);
void     Voxels_Destroy(PKHandle hVoxels);

// Boolean operations
void     Voxels_BoolAdd(PKHandle hThis, PKHandle hOther);
void     Voxels_BoolSubtract(PKHandle hThis, PKHandle hOther);
void     Voxels_BoolIntersect(PKHandle hThis, PKHandle hOther);
// NOTE: BoolAddSmooth is NOT exported in picogk.1.7.dylib

// Offset & morphological
void     Voxels_Offset(PKHandle hThis, float fDistMM);
void     Voxels_DoubleOffset(PKHandle hThis, float fDist1MM, float fDist2MM);
void     Voxels_TripleOffset(PKHandle hThis, float fDistMM);

// Filters
void     Voxels_Gaussian(PKHandle hThis, float fSizeMM);
void     Voxels_Median(PKHandle hThis, float fSizeMM);
void     Voxels_Mean(PKHandle hThis, float fSizeMM);

// Rendering into voxels
void     Voxels_RenderMesh(PKHandle hVoxels, PKHandle hMesh);
void     Voxels_RenderImplicit(PKHandle hVoxels,
                               const PKBBox3* poBounds,
                               PKImplicitDistanceCallback pfnCallback);
void     Voxels_IntersectImplicit(PKHandle hVoxels,
                                  PKImplicitDistanceCallback pfnCallback);
void     Voxels_RenderLattice(PKHandle hVoxels, PKHandle hLattice);

// Projection
void     Voxels_ProjectZSlice(PKHandle hVoxels, float fStartZMM, float fEndZMM);

// Analysis & queries
void     Voxels_CalculateProperties(PKHandle hVoxels,
                                    float* pfVolumeCubicMM,
                                    PKBBox3* poBBox);
void     Voxels_GetSurfaceNormal(PKHandle hVoxels,
                                 const PKVector3* pvecSurfacePoint,
                                 PKVector3* pvecNormal);
bool     Voxels_bClosestPointOnSurface(PKHandle hVoxels,
                                       const PKVector3* pvecSearch,
                                       PKVector3* pvecSurfacePoint);
bool     Voxels_bRayCastToSurface(PKHandle hVoxels,
                                  const PKVector3* pvecOrigin,
                                  const PKVector3* pvecDirection,
                                  PKVector3* pvecSurfacePoint);
bool     Voxels_bIsEqual(PKHandle hThis, PKHandle hOther);

// Voxel grid data access
void     Voxels_GetVoxelDimensions(PKHandle hVoxels,
                                   int32_t* pnXOrigin, int32_t* pnYOrigin, int32_t* pnZOrigin,
                                   int32_t* pnXSize, int32_t* pnYSize, int32_t* pnZSize);
void     Voxels_GetSlice(PKHandle hVoxels,
                         int32_t nZSlice,
                         float* pafBuffer,
                         float* pfBackgroundValue);
void     Voxels_GetInterpolatedSlice(PKHandle hVoxels,
                                     float fZSlice,
                                     float* pafBuffer,
                                     float* pfBackgroundValue);

// ---------------------------------------------------------------------------
// MARK: - PolyLine Functions (7)
// ---------------------------------------------------------------------------

PKHandle PolyLine_hCreate(const PKColorFloat* pclrColor);
bool     PolyLine_bIsValid(PKHandle hPolyLine);
void     PolyLine_Destroy(PKHandle hPolyLine);
int32_t  PolyLine_nAddVertex(PKHandle hPolyLine, const PKVector3* pvecVertex);
int32_t  PolyLine_nVertexCount(PKHandle hPolyLine);
void     PolyLine_GetVertex(PKHandle hPolyLine, int32_t nIndex, PKVector3* pvecVertex);
void     PolyLine_GetColor(PKHandle hPolyLine, PKColorFloat* pclrColor);

// ---------------------------------------------------------------------------
// MARK: - Scalar Field Functions (12)
// ---------------------------------------------------------------------------

PKHandle ScalarField_hCreate(void);
PKHandle ScalarField_hCreateCopy(PKHandle hSource);
PKHandle ScalarField_hCreateFromVoxels(PKHandle hVoxels);
PKHandle ScalarField_hBuildFromVoxels(PKHandle hVoxels,
                                      float fScalarValue,
                                      float fSdThreshold);
bool     ScalarField_bIsValid(PKHandle hField);
void     ScalarField_Destroy(PKHandle hField);
void     ScalarField_SetValue(PKHandle hField,
                              const PKVector3* pvecPosition,
                              float fValue);
bool     ScalarField_bGetValue(PKHandle hField,
                               const PKVector3* pvecPosition,
                               float* pfValue);
void     ScalarField_RemoveValue(PKHandle hField,
                                 const PKVector3* pvecPosition);
void     ScalarField_GetVoxelDimensions(PKHandle hField,
                                        int32_t* pnXOrigin, int32_t* pnYOrigin, int32_t* pnZOrigin,
                                        int32_t* pnXSize, int32_t* pnYSize, int32_t* pnZSize);
void     ScalarField_GetSlice(PKHandle hField,
                              int32_t nZSlice,
                              float* pafBuffer);
void     ScalarField_TraverseActive(PKHandle hField,
                                    PKScalarFieldTraverseCallback pfnCallback);

// ---------------------------------------------------------------------------
// MARK: - Vector Field Functions (10)
// ---------------------------------------------------------------------------

PKHandle VectorField_hCreate(void);
PKHandle VectorField_hCreateCopy(PKHandle hSource);
PKHandle VectorField_hCreateFromVoxels(PKHandle hVoxels);
PKHandle VectorField_hBuildFromVoxels(PKHandle hVoxels,
                                      const PKVector3* pvecValue,
                                      float fSdThreshold);
bool     VectorField_bIsValid(PKHandle hField);
void     VectorField_Destroy(PKHandle hField);
void     VectorField_SetValue(PKHandle hField,
                              const PKVector3* pvecPosition,
                              const PKVector3* pvecValue);
bool     VectorField_bGetValue(PKHandle hField,
                               const PKVector3* pvecPosition,
                               PKVector3* pvecValue);
void     VectorField_RemoveValue(PKHandle hField,
                                 const PKVector3* pvecPosition);
void     VectorField_TraverseActive(PKHandle hField,
                                    PKVectorFieldTraverseCallback pfnCallback);

// ---------------------------------------------------------------------------
// MARK: - Viewer Functions (17)
// ---------------------------------------------------------------------------

PKHandle Viewer_hCreate(const char* pszWindowTitle,
                        const PKVector2* pvecSize,
                        PKInfoCallback          pfnInfoCallback,
                        PKUpdateCallback        pfnUpdateCallback,
                        PKKeyPressedCallback    pfnKeyPressedCallback,
                        PKMouseMovedCallback    pfnMouseMovedCallback,
                        PKMouseButtonCallback   pfnMouseButtonCallback,
                        PKScrollWheelCallback   pfnScrollWheelCallback,
                        PKWindowSizeCallback    pfnWindowSizeCallback);
bool     Viewer_bIsValid(PKHandle hViewer);
void     Viewer_Destroy(PKHandle hViewer);
void     Viewer_RequestUpdate(PKHandle hViewer);
bool     Viewer_bPoll(PKHandle hViewer);
bool     Viewer_RequestScreenShot(PKHandle hViewer, const char* pszPath);
bool     Viewer_bLoadLightSetup(PKHandle hViewer,
                                const uint8_t* pabyDiffuseBuffer, int32_t nDiffuseSize,
                                const uint8_t* pabySpecularBuffer, int32_t nSpecularSize);
void     Viewer_RequestClose(PKHandle hViewer);

void     Viewer_AddMesh(PKHandle hViewer, int32_t nGroupID, PKHandle hMesh);
void     Viewer_RemoveMesh(PKHandle hViewer, PKHandle hMesh);
void     Viewer_AddPolyLine(PKHandle hViewer, int32_t nGroupID, PKHandle hPolyLine);
void     Viewer_RemovePolyLine(PKHandle hViewer, PKHandle hPolyLine);
void     Viewer_SetGroupVisible(PKHandle hViewer, int32_t nGroupID, bool bVisible);
void     Viewer_SetGroupStatic(PKHandle hViewer, int32_t nGroupID, bool bStatic);
void     Viewer_SetGroupMaterial(PKHandle hViewer, int32_t nGroupID,
                                 const PKColorFloat* pclrColor,
                                 float fMetallic, float fRoughness);
void     Viewer_SetGroupMatrix(PKHandle hViewer, int32_t nGroupID,
                               const PKMatrix4x4* pmatTransform);

// ---------------------------------------------------------------------------
// MARK: - VDB File I/O Functions (12)
// ---------------------------------------------------------------------------

PKHandle VdbFile_hCreate(void);
PKHandle VdbFile_hCreateFromFile(const char* pszFilePath);
bool     VdbFile_bIsValid(PKHandle hFile);
void     VdbFile_Destroy(PKHandle hFile);
bool     VdbFile_bSaveToFile(PKHandle hFile, const char* pszFilePath);

PKHandle VdbFile_hGetVoxels(PKHandle hFile, int32_t nIndex);
int32_t  VdbFile_nAddVoxels(PKHandle hFile, const char* pszFieldName, PKHandle hVoxels);
PKHandle VdbFile_hGetScalarField(PKHandle hFile, int32_t nIndex);
int32_t  VdbFile_nAddScalarField(PKHandle hFile, const char* pszFieldName, PKHandle hField);
PKHandle VdbFile_hGetVectorField(PKHandle hFile, int32_t nIndex);
int32_t  VdbFile_nAddVectorField(PKHandle hFile, const char* pszFieldName, PKHandle hField);

int32_t  VdbFile_nFieldCount(PKHandle hFile);
void     VdbFile_GetFieldName(PKHandle hFile, int32_t nIndex, char* pszBuffer);
int32_t  VdbFile_nFieldType(PKHandle hFile, int32_t nIndex);

// ---------------------------------------------------------------------------
// MARK: - Field Metadata Functions (13)
// ---------------------------------------------------------------------------

PKHandle Metadata_hFromVoxels(PKHandle hVoxels);
PKHandle Metadata_hFromScalarField(PKHandle hScalarField);
PKHandle Metadata_hFromVectorField(PKHandle hVectorField);
void     Metadata_Destroy(PKHandle hMetadata);

int32_t  Metadata_nCount(PKHandle hMetadata);
int32_t  Metadata_nNameLengthAt(PKHandle hMetadata, int32_t nIndex);
bool     Metadata_bGetNameAt(PKHandle hMetadata, int32_t nIndex,
                             char* pszName, int32_t nMaxLen);
int32_t  Metadata_nTypeAt(PKHandle hMetadata, const char* pszName);
int32_t  Metadata_nStringLengthAt(PKHandle hMetadata, const char* pszFieldName);
bool     Metadata_bGetStringAt(PKHandle hMetadata, const char* pszFieldName,
                               char* pszValue, int32_t nMaxLen);
bool     Metadata_bGetFloatAt(PKHandle hMetadata, const char* pszFieldName,
                              float* pfValue);
bool     Metadata_bGetVectorAt(PKHandle hMetadata, const char* pszFieldName,
                               PKVector3* pvecValue);

void     Metadata_SetStringValue(PKHandle hMetadata, const char* pszFieldName,
                                 const char* pszValue);
void     Metadata_SetFloatValue(PKHandle hMetadata, const char* pszFieldName,
                                float fValue);
void     Metadata_SetVectorValue(PKHandle hMetadata, const char* pszFieldName,
                                 const PKVector3* pvecValue);

// NOTE: MetaData_RemoveValue has inconsistent casing in dylib (MetaData vs Metadata)
void     MetaData_RemoveValue(PKHandle hMetadata, const char* pszFieldName);

#ifdef __cplusplus
}
#endif
