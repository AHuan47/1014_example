using UnityEngine;
using UnityEngine.Playables;
using UnityEngine.Animations;

public class AnimationDemoController : MonoBehaviour
{
    [SerializeField] private Animator Animator_1;
    [SerializeField] private Animator Animator_2;
    [SerializeField] private Animator Animator_3;
    [SerializeField] private Animator Animator_4;

    [SerializeField] private AnimationClip clip1;
    [SerializeField] private AnimationClip clip2;
    [SerializeField] private AnimationClip clip3;
    [SerializeField] private AnimationClip clip4;

    private PlayableGraph graph1;
    private PlayableGraph graph2;
    private PlayableGraph graph3;
    private PlayableGraph graph4;

    public void PlayDialogAnimation()
    {
        PlayClip(Animator_1, clip1, ref graph1);
    }

    public void PlayDialogAnimation2()
    {
        PlayClip(Animator_2, clip2, ref graph2);
    }

    public void PlayDialogAnimation3()
    {
        PlayClip(Animator_3, clip3, ref graph3);
    }

    public void PlayDialogAnimation4()
    {
        PlayClip(Animator_4, clip4, ref graph4);
    }

    private void PlayClip(
        Animator animator,
        AnimationClip clip,
        ref PlayableGraph graph)
    {
        if (animator == null || clip == null)
            return;

        animator.gameObject.SetActive(true);

        if (graph.IsValid())
            graph.Destroy();

        graph = PlayableGraph.Create("AnimationDemo");

        var playable = AnimationClipPlayable.Create(graph, clip);

        var output = AnimationPlayableOutput.Create(
            graph,
            "Animation",
            animator
        );

        output.SetSourcePlayable(playable);

        graph.Play();
        graph.Evaluate(0f);
    }

    private void OnDisable()
    {
        if (graph1.IsValid())
            graph1.Destroy();

        if (graph2.IsValid())
            graph2.Destroy();

        if (graph3.IsValid())
            graph3.Destroy();

        if (graph4.IsValid())
            graph4.Destroy();
    }
}