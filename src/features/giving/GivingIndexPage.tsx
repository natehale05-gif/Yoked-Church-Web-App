import { useCallback, useMemo, useState } from 'react';
import {
  Badge,
  BlockStack,
  Box,
  Card,
  ChoiceList,
  EmptyState,
  IndexFilters,
  IndexTable,
  InlineStack,
  Page,
  Text,
  useBreakpoints,
  useIndexResourceState,
  useSetIndexFiltersMode,
} from '@shopify/polaris';
import type { IndexFiltersProps, TabProps } from '@shopify/polaris';
import { useNavigate } from 'react-router-dom';

import { useChurch } from '../../core/church-context';
import { churchPath } from '../../core/tenant';
import { allGifts, formatAmount, formatDate, type GiftRow } from './gifts';

/**
 * Shopify's Orders page, for money coming in.
 *
 * Every part of the pattern is deliberate and is why the rebuild
 * happened:
 *
 * - **Full width.** Polaris' own guidance: an index of rows with many
 *   columns gets the whole page, not a centred column.
 * - **Tabs are saved views, never navigation.** The Flutter build used a
 *   tab strip to move between nineteen *sections*, which is the one
 *   thing Shopify never does with tabs.
 * - **Bulk selection with a promoted action**, so a treasurer can act on
 *   forty rows without opening forty pages.
 * - **Row actions are quiet.** No primary buttons in a table.
 */
const VIEWS = [
  { id: 'all', label: 'All', match: () => true },
  { id: 'online', label: 'Online', match: (g: GiftRow) => g.method === 'Online' },
  { id: 'offline', label: 'Cash & check', match: (g: GiftRow) => g.method === 'Cash' || g.method === 'Check' },
] as const;

export function GivingIndexPage() {
  const church = useChurch();
  const navigate = useNavigate();

  const gifts = useMemo(() => allGifts(), []);
  const funds = useMemo(() => [...new Set(gifts.map((g) => g.fund))].sort(), [gifts]);

  // Below `sm`, Polaris renders each row as a list item instead of a
  // table row. Without it the table keeps all five columns and scrolls
  // sideways inside the card, which put Amount - the column a treasurer
  // opens this page for - off the right-hand edge of a phone. It reads
  // as a normal table until you look at one.
  const { smDown } = useBreakpoints();

  const [selectedView, setSelectedView] = useState(0);
  const [queryValue, setQueryValue] = useState('');
  const [fundFilter, setFundFilter] = useState<string[]>([]);
  const { mode, setMode } = useSetIndexFiltersMode();

  const rows = useMemo(() => {
    const view = VIEWS[selectedView] ?? VIEWS[0];
    const query = queryValue.trim().toLowerCase();

    return gifts.filter((gift) => {
      if (!view.match(gift)) return false;
      if (fundFilter.length > 0 && !fundFilter.includes(gift.fund)) return false;
      if (query === '') return true;
      return (
        gift.donorName.toLowerCase().includes(query) ||
        gift.fund.toLowerCase().includes(query) ||
        gift.note.toLowerCase().includes(query)
      );
    });
  }, [gifts, selectedView, queryValue, fundFilter]);

  const resourceName = { singular: 'gift', plural: 'gifts' };
  const { selectedResources, allResourcesSelected, handleSelectionChange } =
    useIndexResourceState(rows as unknown as Array<{ [key: string]: unknown; id: string }>);

  const tabs: TabProps[] = VIEWS.map((view, index) => ({
    id: view.id,
    content: view.label,
    onAction: () => setSelectedView(index),
  }));

  const filters: IndexFiltersProps['filters'] = [
    {
      key: 'fund',
      label: 'Fund',
      filter: (
        <ChoiceList
          title="Fund"
          titleHidden
          allowMultiple
          choices={funds.map((fund) => ({ label: fund, value: fund }))}
          selected={fundFilter}
          onChange={setFundFilter}
        />
      ),
      shortcut: true,
    },
  ];

  const appliedFilters: IndexFiltersProps['appliedFilters'] =
    fundFilter.length > 0
      ? [
          {
            key: 'fund',
            label: `Fund: ${fundFilter.join(', ')}`,
            onRemove: () => setFundFilter([]),
          },
        ]
      : [];

  const clearAll = useCallback(() => {
    setFundFilter([]);
    setQueryValue('');
  }, []);

  const total = rows.reduce((sum, gift) => sum + gift.amount, 0);

  return (
    <Page
      fullWidth
      title="Giving"
      subtitle={`${rows.length} ${rows.length === 1 ? 'gift' : 'gifts'} · ${formatAmount(total)}`}
      primaryAction={{ content: 'Record a gift', onAction: () => undefined, disabled: true }}
    >
      <Card padding="0">
        <IndexFilters
          tabs={tabs}
          selected={selectedView}
          onSelect={setSelectedView}
          queryValue={queryValue}
          queryPlaceholder="Search by donor, fund or note"
          onQueryChange={setQueryValue}
          onQueryClear={() => setQueryValue('')}
          filters={filters}
          appliedFilters={appliedFilters}
          onClearAll={clearAll}
          mode={mode}
          setMode={setMode}
          cancelAction={{ onAction: clearAll, disabled: false, loading: false }}
          canCreateNewView={false}
        />

        <IndexTable
          condensed={smDown}
          resourceName={resourceName}
          itemCount={rows.length}
          selectedItemsCount={allResourcesSelected ? 'All' : selectedResources.length}
          onSelectionChange={handleSelectionChange}
          promotedBulkActions={[
            { content: 'Export selected', onAction: () => undefined },
          ]}
          headings={[
            { title: 'Date' },
            { title: 'Donor' },
            { title: 'Fund' },
            { title: 'Method' },
            { title: 'Amount', alignment: 'end' },
          ]}
          emptyState={
            <EmptyState heading="No gifts match these filters" image="">
              <p>Clear the search or the fund filter to see the rest.</p>
            </EmptyState>
          }
        >
          {rows.map((gift, index) => (
            <IndexTable.Row
              id={gift.id}
              key={gift.id}
              position={index}
              selected={selectedResources.includes(gift.id)}
              onClick={() => navigate(churchPath(church.churchId, `/admin/giving/${gift.id}`))}
            >
              {smDown ? (
                // A phone gets the row stacked, with the two things that
                // identify a gift on the first line and the amount where
                // the eye already is.
                <Box padding="300">
                  <BlockStack gap="100">
                    <InlineStack align="space-between" blockAlign="start" gap="200" wrap={false}>
                      <Text as="span" variant="bodyMd" fontWeight="semibold">
                        {gift.donorName}
                      </Text>
                      <Text as="span" variant="bodyMd" numeric fontWeight="semibold">
                        {formatAmount(gift.amount)}
                      </Text>
                    </InlineStack>
                    <InlineStack align="space-between" blockAlign="center" gap="200">
                      <Text as="span" variant="bodySm" tone="subdued">
                        {`${formatDate(gift.date)} · ${gift.fund}`}
                      </Text>
                      <Badge tone={gift.method === 'Online' ? 'success' : undefined}>
                        {gift.method}
                      </Badge>
                    </InlineStack>
                  </BlockStack>
                </Box>
              ) : (
                <>
              <IndexTable.Cell>
                <Text as="span" variant="bodyMd">
                  {formatDate(gift.date)}
                </Text>
              </IndexTable.Cell>
              <IndexTable.Cell>
                <Text as="span" variant="bodyMd" fontWeight="semibold">
                  {gift.donorName}
                </Text>
              </IndexTable.Cell>
              <IndexTable.Cell>{gift.fund}</IndexTable.Cell>
              <IndexTable.Cell>
                <Badge tone={gift.method === 'Online' ? 'success' : undefined}>{gift.method}</Badge>
              </IndexTable.Cell>
              <IndexTable.Cell>
                <Text as="span" variant="bodyMd" numeric alignment="end">
                  {formatAmount(gift.amount)}
                </Text>
              </IndexTable.Cell>
                </>
              )}
            </IndexTable.Row>
          ))}
        </IndexTable>
      </Card>
    </Page>
  );
}
