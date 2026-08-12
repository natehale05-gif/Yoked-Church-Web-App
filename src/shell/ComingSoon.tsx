import { Card, EmptyState, Page } from '@shopify/polaris';

/**
 * A destination the sidebar offers and the rebuild has not reached.
 *
 * The alternative was to leave those items out of the sidebar until
 * their screen existed, which hides how much is left and makes the shell
 * impossible to judge. The alternative to *that* was to let them 404,
 * which reads as a broken app rather than an unfinished one.
 *
 * So: the nav is the finished IA from day one, and anything behind it
 * that is not built says exactly that, by name. Each one is deleted by
 * the phase that builds the real screen.
 */
export function ComingSoon({ title, phase }: { title: string; phase: string }) {
  return (
    <Page title={title}>
      <Card>
        <EmptyState heading={`${title} is not rebuilt yet`} image="">
          <p>
            This screen arrives in {phase}. It exists in the Flutter app this is replacing, and
            nothing has been deleted there until its replacement works.
          </p>
        </EmptyState>
      </Card>
    </Page>
  );
}
