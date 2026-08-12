import { BlockStack, Box, Button, Card, InlineGrid, Text, useBreakpoints } from '@shopify/polaris';

import { useChurch } from '../../core/church-context';
import { useSession } from './session';

const ROLES = [
  { as: 'member', label: 'Member', detail: 'Groups, giving history, kids check-in' },
  { as: 'staff', label: 'Staff', detail: 'Everything above, plus the content tools' },
  { as: 'admin', label: 'Admin', detail: 'Everything, plus people, reports and settings' },
] as const;

/**
 * The way into the demo.
 *
 * Three buttons rather than a password field, for the same reason the
 * Flutter build had preview cards: there is no Firebase project behind
 * this deployment, so a real credential would have nothing to check
 * against and the app would be unopenable — including by whoever is
 * reviewing it.
 *
 * P2 puts the real form here and moves this behind a demo flag.
 */
export function SignInPage() {
  const church = useChurch();
  const session = useSession();
  const { smDown } = useBreakpoints();

  return (
    // Padded here rather than by `Page`. This screen sits outside the
    // admin `Frame` - it is what you see before there is an admin to
    // frame - and without a Frame around it Polaris' page padding is
    // zero, so at 390px every line of text sat flush against the edge
    // of the screen.
    <Box paddingBlock="1200" paddingInline="400">
      <Box maxWidth="480px" width="100%">
        <BlockStack gap="500">
          <BlockStack gap="200">
            <Text as="h1" variant="headingLg">
              {church.settings.churchName}
            </Text>
            <Text as="p" tone="subdued">
              This deployment has no accounts behind it yet. Pick a role to look around as.
            </Text>
          </BlockStack>

          <Card>
            <BlockStack gap="400">
              {ROLES.map((role) => (
                // One column on a phone, two side by side above it. The
                // first version was an `InlineStack` with
                // `space-between`, which at 390px squeezed the
                // description into two lines and then dropped the button
                // onto a third, unaligned with anything.
                <InlineGrid key={role.as} columns={smDown ? 1 : ['twoThirds', 'oneThird']} gap="300">
                  <BlockStack gap="050">
                    <Text as="h2" variant="headingSm">
                      {role.label}
                    </Text>
                    <Text as="p" tone="subdued" variant="bodySm">
                      {role.detail}
                    </Text>
                  </BlockStack>
                  <Button
                    fullWidth
                    variant={role.as === 'admin' ? 'primary' : 'secondary'}
                    onClick={() => session.signIn(role.as)}
                  >
                    {`Sign in as ${role.label}`}
                  </Button>
                </InlineGrid>
              ))}
            </BlockStack>
          </Card>
        </BlockStack>
      </Box>
    </Box>
  );
}
