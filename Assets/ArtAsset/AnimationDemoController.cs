using UnityEngine;

public class AnimationDemoController : MonoBehaviour
{
    [SerializeField] private Animator Animator_1;
    [SerializeField] private Animator Animator_2;

    // Animator ¸Ìªº State ¦WºÙ
    [SerializeField] private string dialogStateName1 = "Task1";
    [SerializeField] private string dialogStateName2 = "Task2";


    public void PlayDialogAnimation()
    {
        Animator_1.gameObject.SetActive(true);

        Animator_1.Play(dialogStateName1, 0, 0f);
        Animator_1.Update(0f);
    }

    public void PlayDialogAnimation2()
    {
        Animator_2.gameObject.SetActive(true);

        Animator_2.Play(dialogStateName2, 0, 0f);
        Animator_2.Update(0f);
    }
}