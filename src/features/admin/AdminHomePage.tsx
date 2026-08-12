import {
  BlockStack,
  Box,
  Button,
  Card,
  Icon,
  InlineStack,
  Layout,
  Page,
  ProgressBar,
  Text,
} from '@shopify/polaris';
import { CheckCircleIcon } from '@shopify/polaris-icons';
import { useNavigate } from 'react-router-dom';

import { useChurch } from '../../core/church-context';
import { churchPath } from '../../core/tenant';
import { setupProgress, setupSteps } from './setup-guide';

/**
 * Shopify's Home: the setup guide first, then what happened lately.
 *
 * The guide is at the top and stays there until it is finished, which is
 * Shopify's own behaviour and the reason a new merchant ever finishes
 * configuring a store.
 */
export function AdminHomePage() {
  const church = useChurch();
  const navigate = useNavigate();

  const steps = setupSteps(church.settings);
  const { done, total } = setupProgress(steps);
  const finished = done === total;

  return (
    <Page title={church.settings.churchName}>
      <Layout>
        <Layout.Section>
          <BlockStack gap="400">
            {!finished && (
              <Card>
                <BlockStack gap="400">
                  <BlockStack gap="200">
                    <Text as="h2" variant="headingMd">
                      Set up your church
                    </Text>
                    <Text as="p" tone="subdued">
                      {`${done} of ${total} steps complete`}
                    </Text>
                    <ProgressBar progress={(done / total) * 100} size="small" tone="primary" />
                  </BlockStack>

                  <BlockStack gap="300">
                    {steps.map((step) => (
                      <InlineStack key={step.id} gap="300" blockAlign="start" wrap={false}>
                        <Box paddingBlockStart="050">
                          <Icon
                            source={CheckCircleIcon}
                            tone={step.done ? 'success' : 'subdued'}
                          />
                        </Box>
                        <BlockStack gap="100">
                          <Text as="h3" variant="headingSm" tone={step.done ? 'subdued' : undefined}>
                            {step.title}
                          </Text>
                          <Text as="p" tone="subdued" variant="bodySm">
                            {step.description}
                          </Text>
                          {!step.done && (
                            <Box paddingBlockStart="100">
                              <Button
                                size="slim"
                                onClick={() => navigate(churchPath(church.churchId, step.path))}
                              >
                                {step.title}
                              </Button>
                            </Box>
                          )}
                        </BlockStack>
                      </InlineStack>
                    ))}
                  </BlockStack>
                </BlockStack>
              </Card>
            )}

            <Card>
              <BlockStack gap="200">
                <Text as="h2" variant="headingMd">
                  This week
                </Text>
                <Text as="p" tone="subdued">
                  Attendance, giving and first-time visitors land here in P4, once the data layer
                  behind them is ported. Until then this card says so rather than showing numbers
                  nobody measured.
                </Text>
              </BlockStack>
            </Card>
          </BlockStack>
        </Layout.Section>
      </Layout>
    </Page>
  );
}
