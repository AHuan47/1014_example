using UnityEngine;

[ExecuteAlways]
[RequireComponent(typeof(Camera))]
public class PostProcessController : MonoBehaviour
{
    [Header("Materials")]
    [SerializeField] private Material crtMaterial;

    [Header("CRT Settings")]
    [SerializeField] private bool enableCRT = true;

    [Range(0f, 1f)]
    [SerializeField] private float scanlineIntensity = 0.25f;

    [Range(50f, 1000f)]
    [SerializeField] private float scanlineCount = 300f;

    [Range(0f, 0.3f)]
    [SerializeField] private float curvature = 0.08f;

    [Range(0f, 0.02f)]
    [SerializeField] private float chromaticAberration = 0.003f;

    [Range(0f, 2f)]
    [SerializeField] private float vignetteIntensity = 0.5f;

    [Range(0f, 1f)]
    [SerializeField] private float noiseIntensity = 0.03f;

    [Range(0f, 0.2f)]
    [SerializeField] private float flickerIntensity = 0.02f;

    // Shader Property IDs
    private static readonly int ScanlineIntensityID =
        Shader.PropertyToID("_ScanlineIntensity");

    private static readonly int ScanlineCountID =
        Shader.PropertyToID("_ScanlineCount");

    private static readonly int CurvatureID =
        Shader.PropertyToID("_Curvature");

    private static readonly int ChromaticAberrationID =
        Shader.PropertyToID("_ChromaticAberration");

    private static readonly int VignetteIntensityID =
        Shader.PropertyToID("_VignetteIntensity");

    private static readonly int NoiseIntensityID =
        Shader.PropertyToID("_NoiseIntensity");

    private static readonly int FlickerIntensityID =
        Shader.PropertyToID("_FlickerIntensity");


    public bool CRTEnabled => enableCRT;

    public Material CRTMaterial => crtMaterial;


    private void OnEnable()
    {
        UpdateMaterials();
    }

    private void OnValidate()
    {
        UpdateMaterials();
    }

    private void UpdateMaterials()
    {
        if (crtMaterial == null)
            return;

        crtMaterial.SetFloat(
            ScanlineIntensityID,
            scanlineIntensity
        );

        crtMaterial.SetFloat(
            ScanlineCountID,
            scanlineCount
        );

        crtMaterial.SetFloat(
            CurvatureID,
            curvature
        );

        crtMaterial.SetFloat(
            ChromaticAberrationID,
            chromaticAberration
        );

        crtMaterial.SetFloat(
            VignetteIntensityID,
            vignetteIntensity
        );

        crtMaterial.SetFloat(
            NoiseIntensityID,
            noiseIntensity
        );

        crtMaterial.SetFloat(
            FlickerIntensityID,
            flickerIntensity
        );
    }

    public void SetCRTEnabled(bool enabled)
    {
        enableCRT = enabled;
    }

    public void SetCRTIntensity(float intensity)
    {
        scanlineIntensity = Mathf.Clamp01(intensity);
        UpdateMaterials();
    }
}