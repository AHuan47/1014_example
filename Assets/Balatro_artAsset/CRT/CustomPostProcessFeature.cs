using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;

public class CustomPostProcessFeature : ScriptableRendererFeature
{
    private CRTPass crtPass;

    public override void Create()
    {
        crtPass = new CRTPass();
        crtPass.renderPassEvent =
            RenderPassEvent.AfterRenderingPostProcessing;
    }

    public override void AddRenderPasses(
        ScriptableRenderer renderer,
        ref RenderingData renderingData)
    {
        Camera camera = renderingData.cameraData.camera;

        if (camera == null)
        {
            return;
        }

        if (!camera.TryGetComponent(out PostProcessController controller))
        {
            return;
        }
        if (!controller.CRTEnabled)
        {
            return;
        }

        if (controller.CRTMaterial == null)
        {
            return;
        }

        crtPass.SetMaterial(controller.CRTMaterial);
        renderer.EnqueuePass(crtPass);
    }

    private class CRTPass : ScriptableRenderPass
    {
        private Material material;

        public void SetMaterial(Material crtMaterial)
        {
            material = crtMaterial;
        }

        public override void RecordRenderGraph(
            RenderGraph renderGraph,
            ContextContainer frameData)
        {
            if (material == null)
                return;

            UniversalResourceData resourceData =
                frameData.Get<UniversalResourceData>();

            if (resourceData.isActiveTargetBackBuffer)
            {
                return;
            }

            TextureHandle source =
                resourceData.activeColorTexture;

            if (!source.IsValid())
            {
                return;
            }

            UniversalCameraData cameraData =
                frameData.Get<UniversalCameraData>();

            RenderTextureDescriptor descriptor =
                cameraData.cameraTargetDescriptor;

            descriptor.depthBufferBits = 0;
            descriptor.msaaSamples = 1;

            TextureHandle destination =
                UniversalRenderer.CreateRenderGraphTexture(
                    renderGraph,
                    descriptor,
                    "_CRTTempTexture",
                    false
                );

            RenderGraphUtils.BlitMaterialParameters parameters =
                new RenderGraphUtils.BlitMaterialParameters(
                    source,
                    destination,
                    material,
                    0
                );

            renderGraph.AddBlitPass(
                parameters,
                "CRT Post Process"
            );

            var copyParameters =
                new RenderGraphUtils.BlitMaterialParameters(
                    destination,
                    source,
                    Blitter.GetBlitMaterial(TextureDimension.Tex2D),
                    0
                );

            renderGraph.AddBlitPass(
                copyParameters,
                "CRT Copy Back"
            );
        }
    }
}