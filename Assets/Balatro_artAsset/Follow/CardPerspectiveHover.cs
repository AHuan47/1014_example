using UnityEngine;

#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

public class CardPerspectiveHover : MonoBehaviour
{
  
    [SerializeField] private Camera targetCamera;
    [SerializeField] private MeshRenderer cardRenderer;

    //-------------follow effect---------------

    [SerializeField] private float followSpeed = 12f;

    private MaterialPropertyBlock propertyBlock;
    private Bounds meshBounds;
    private Vector2 currentTilt;

    private static readonly int TiltId =
        Shader.PropertyToID("_Tilt");

    private static readonly int AspectId =
        Shader.PropertyToID("_Aspect");

    //-------------shake effect----------------

    [SerializeField] private float shakeAngle = 8f;
    [SerializeField] private float shakeFrequency = 5f;
    [SerializeField] private float shakeDecay = 8f;
    [SerializeField] private float shakeDuration = 0.6f;

    private bool wasInside;
    private float shakeTimer;
    private Quaternion initialRotation;

    //-----------------------------------------

    private void Awake()
    {
        if (targetCamera == null)
            targetCamera = Camera.main;

        if (cardRenderer == null)
            return;

        MeshFilter meshFilter =
            cardRenderer.GetComponent<MeshFilter>();

        if (meshFilter == null || meshFilter.sharedMesh == null)
            return;

        meshBounds = meshFilter.sharedMesh.bounds;
        propertyBlock = new MaterialPropertyBlock();

        initialRotation = cardRenderer.transform.localRotation;
        shakeTimer = shakeDuration;
    }

    private void Update()
    {
        if (targetCamera == null ||
            cardRenderer == null ||
            propertyBlock == null)
        {
            return;
        }

        Transform card = cardRenderer.transform;
        Vector2 targetTilt = Vector2.zero;
        bool inside = false;

        if (TryGetMousePosition(out Vector2 mousePosition))
        {
            Vector3 planePoint =
                card.TransformPoint(meshBounds.center);

            Vector3 planeNormal = Vector3.Cross(
                card.TransformVector(Vector3.right),
                card.TransformVector(Vector3.up)
            ).normalized;

            Plane plane = new Plane(planeNormal, planePoint);
            Ray ray = targetCamera.ScreenPointToRay(mousePosition);

            if (plane.Raycast(ray, out float distance))
            {
                Vector3 localPoint =
                    card.InverseTransformPoint(ray.GetPoint(distance));

                Vector3 offset = localPoint - meshBounds.center;
                Vector3 halfSize = meshBounds.extents;

                float x = offset.x / Mathf.Max(halfSize.x, 0.001f);
                float y = offset.y / Mathf.Max(halfSize.y, 0.001f);

                inside =
                    Mathf.Abs(x) <= 1f &&
                    Mathf.Abs(y) <= 1f;

                if (inside)
                    targetTilt = new Vector2(-x, -y);
            }

            if (inside && !wasInside)
                shakeTimer = 0f;

            wasInside = inside;

            float shake = 0f;

            if (shakeTimer < shakeDuration)
            {
                shake =
                    Mathf.Sin(shakeTimer * shakeFrequency * Mathf.PI * 2f)
                    * shakeAngle
                    * Mathf.Exp(-shakeDecay * shakeTimer);

                shakeTimer += Time.deltaTime;
            }

            card.localRotation =
                initialRotation * Quaternion.Euler(0f, 0f, shake);
        }

        float blend =
            1f - Mathf.Exp(-followSpeed * Time.deltaTime);

        currentTilt = Vector2.Lerp(
            currentTilt,
            targetTilt,
            blend
        );

        // 取得實際寬高比
        float width = card.TransformVector(
            Vector3.right * meshBounds.size.x
        ).magnitude;

        float height = card.TransformVector(
            Vector3.up * meshBounds.size.y
        ).magnitude;

        cardRenderer.GetPropertyBlock(propertyBlock);

        propertyBlock.SetVector(
            TiltId,
            new Vector4(currentTilt.x, currentTilt.y, 0f, 0f)
        );

        propertyBlock.SetFloat(
            AspectId,
            width / Mathf.Max(height, 0.001f)
        );

        cardRenderer.SetPropertyBlock(propertyBlock);
    }

    private static bool TryGetMousePosition(out Vector2 position) 
    {
#if ENABLE_INPUT_SYSTEM
        if (Mouse.current != null)
        {
            position = Mouse.current.position.ReadValue();
            return true;
        }
#elif ENABLE_LEGACY_INPUT_MANAGER
        position = Input.mousePosition;
        return true;
#endif

        position = default;
        return false;
    }
}