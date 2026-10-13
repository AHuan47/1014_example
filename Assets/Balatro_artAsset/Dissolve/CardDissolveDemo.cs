using System.Collections;
using UnityEngine;

public class CardDissolveDemo : MonoBehaviour
{
    [SerializeField] private Renderer cardRenderer;

    [Tooltip("拖入你做的粒子！")]
    [SerializeField] private ParticleSystem particles;

    [Tooltip("填 Shader Graph 裡 Dissolve 的 Reference")]
    [SerializeField] private string dissolveReference = "_Dissolve";

    [Min(0.01f)]
    [SerializeField] private float dissolveDuration = 1f;

    [Min(0f)]
    [SerializeField] private float resetDelay = 1f;

    [SerializeField]
    private AnimationCurve dissolveCurve =
        AnimationCurve.Linear(0f, 0f, 1f, 1f);

    private MaterialPropertyBlock block;
    private int dissolveId;
    private Coroutine routine;
    private bool isPlaying;

    private void Awake()
    {
        if (cardRenderer == null)
            cardRenderer = GetComponent<Renderer>();

        block = new MaterialPropertyBlock();
        dissolveId = Shader.PropertyToID(dissolveReference);
    }

    public void PlayDissolve()
    {
        if (!isActiveAndEnabled || isPlaying || cardRenderer == null)
            return;

        if (cardRenderer.sharedMaterial == null ||
            !cardRenderer.sharedMaterial.HasProperty(dissolveId))
        {
            Debug.LogWarning(
                "找不到 Dissolve 屬性，請確認 Reference 名稱。",
                this
            );
            return;
        }

        isPlaying = true;
        routine = StartCoroutine(PlayRoutine());
    }

    private IEnumerator PlayRoutine()
    {
        SetDissolve(0f);

        if (particles != null)
        {
            particles.Stop(
                true,
                ParticleSystemStopBehavior.StopEmittingAndClear
            );

            particles.Play(true);
        }

        float elapsed = 0f;
        float duration = Mathf.Max(dissolveDuration, 0.01f);

        while (elapsed < duration)
        {
            float progress = elapsed / duration;

            SetDissolve(
                Mathf.Clamp01(dissolveCurve.Evaluate(progress))
            );

            elapsed += Time.deltaTime;
            yield return null;
        }

        SetDissolve(1f);

        if (particles != null)
        {
            particles.Stop(
                true,
                ParticleSystemStopBehavior.StopEmitting
            );
        }

        yield return new WaitForSeconds(resetDelay);

        while (particles != null && particles.IsAlive(true))
            yield return null;

        SetDissolve(0f);

        routine = null;
        isPlaying = false;
    }

    private void SetDissolve(float value)
    {
        cardRenderer.GetPropertyBlock(block);
        block.SetFloat(dissolveId, value);
        cardRenderer.SetPropertyBlock(block);
    }

    private void OnDisable()
    {
        if (routine != null)
        {
            StopCoroutine(routine);
            routine = null;
        }

        if (particles != null)
        {
            particles.Stop(
                true,
                ParticleSystemStopBehavior.StopEmittingAndClear
            );
        }

        if (isPlaying && cardRenderer != null)
            SetDissolve(0f);

        isPlaying = false;
    }
}