import { useMemo, useState } from 'react';
import {
  Badge,
  BlockStack,
  Card,
  ContextualSaveBar,
  FormLayout,
  InlineStack,
  Layout,
  Page,
  Select,
  Text,
  TextField,
} from '@shopify/polaris';
import { useNavigate, useParams } from 'react-router-dom';

import { useChurch } from '../../core/church-context';
import { churchPath } from '../../core/tenant';
import { allGifts, formatAmount, formatDate } from './gifts';

/**
 * Shopify's resource detail page: the record on the left, the context on
 * the right, and a save bar that appears the moment anything changes.
 *
 * The right rail is not decoration. Shopify puts the *other* records
 * that touch this one there - the customer, the payment, the notes - so
 * the page answers "who is this and what else have they done" without a
 * second navigation. For a gift that is the donor and their history.
 */
export function GivingDetailPage() {
  const { giftId } = useParams();
  const church = useChurch();
  const navigate = useNavigate();

  const gifts = useMemo(() => allGifts(), []);
  const gift = gifts.find((g) => g.id === giftId);

  const [fund, setFund] = useState(gift?.fund ?? '');
  const [method, setMethod] = useState(gift?.method ?? '');
  const [note, setNote] = useState(gift?.note ?? '');

  if (gift === undefined) {
    return (
      <Page
        title="Gift not found"
        backAction={{ onAction: () => navigate(churchPath(church.churchId, '/admin/giving')) }}
      >
        <Card>
          <Text as="p">
            This gift has been deleted, or the link is wrong. Everything else is still on the giving
            page.
          </Text>
        </Card>
      </Page>
    );
  }

  const dirty = fund !== gift.fund || method !== gift.method || note !== gift.note;

  const discard = () => {
    setFund(gift.fund);
    setMethod(gift.method);
    setNote(gift.note);
  };

  const funds = [...new Set(gifts.map((g) => g.fund))].sort();
  const methods = [...new Set(gifts.map((g) => g.method))].sort();

  const donorGifts = gifts.filter((g) => g.uid === gift.uid);
  const donorTotal = donorGifts.reduce((sum, g) => sum + g.amount, 0);

  return (
    // No `Frame` here. `ContextualSaveBar` attaches to the nearest
    // ancestor Frame - `AdminFrame` already is one - and nesting a
    // second one made the inner Frame reserve space for a sidebar it
    // does not have, pushing the whole page a couple of hundred pixels
    // to the right. Visible immediately in a screenshot, invisible to
    // every assertion.
    <>
      {dirty && (
        <ContextualSaveBar
          message="Unsaved changes"
          saveAction={{
            // Writes land in P2 with the repository behind them. Until
            // then the bar appears and discards honestly, and saving
            // says it cannot rather than pretending it did.
            onAction: () => undefined,
            disabled: true,
            content: 'Save',
          }}
          discardAction={{ onAction: discard, content: 'Discard' }}
        />
      )}

      <Page
        title={formatAmount(gift.amount)}
        titleMetadata={<Badge tone={gift.method === 'Online' ? 'success' : undefined}>{gift.method}</Badge>}
        subtitle={`${gift.donorName} · ${formatDate(gift.date)}`}
        backAction={{ onAction: () => navigate(churchPath(church.churchId, '/admin/giving')) }}
      >
        <Layout>
          <Layout.Section>
            <Card>
              <BlockStack gap="400">
                <Text as="h2" variant="headingMd">
                  Gift
                </Text>
                <FormLayout>
                  <FormLayout.Group>
                    <Select
                      label="Fund"
                      options={funds.map((f) => ({ label: f, value: f }))}
                      value={fund}
                      onChange={setFund}
                    />
                    <Select
                      label="Method"
                      options={methods.map((m) => ({ label: m, value: m }))}
                      value={method}
                      onChange={setMethod}
                    />
                  </FormLayout.Group>
                  <TextField
                    label="Note"
                    value={note}
                    onChange={setNote}
                    multiline={3}
                    autoComplete="off"
                    helpText="Shown on the donor's giving statement."
                  />
                </FormLayout>
              </BlockStack>
            </Card>
          </Layout.Section>

          <Layout.Section variant="oneThird">
            <BlockStack gap="400">
              <Card>
                <BlockStack gap="300">
                  <Text as="h2" variant="headingMd">
                    Donor
                  </Text>
                  <Text as="p" fontWeight="semibold">
                    {gift.donorName}
                  </Text>
                  <InlineStack align="space-between">
                    <Text as="span" tone="subdued">
                      Gifts
                    </Text>
                    <Text as="span" numeric>
                      {String(donorGifts.length)}
                    </Text>
                  </InlineStack>
                  <InlineStack align="space-between">
                    <Text as="span" tone="subdued">
                      Total given
                    </Text>
                    <Text as="span" numeric fontWeight="semibold">
                      {formatAmount(donorTotal)}
                    </Text>
                  </InlineStack>
                </BlockStack>
              </Card>

              <Card>
                <BlockStack gap="300">
                  <Text as="h2" variant="headingMd">
                    Recent gifts
                  </Text>
                  {donorGifts.slice(0, 5).map((other) => (
                    <InlineStack key={other.id} align="space-between">
                      <Text as="span" tone={other.id === gift.id ? undefined : 'subdued'}>
                        {formatDate(other.date)}
                      </Text>
                      <Text as="span" numeric>
                        {formatAmount(other.amount)}
                      </Text>
                    </InlineStack>
                  ))}
                </BlockStack>
              </Card>
            </BlockStack>
          </Layout.Section>
        </Layout>
      </Page>
    </>
  );
}
