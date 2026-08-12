import { Card, EmptyState, Page } from '@shopify/polaris';
import { useLocation, useNavigate } from 'react-router-dom';

export function NotFoundPage() {
  const location = useLocation();
  const navigate = useNavigate();

  return (
    <Page narrowWidth>
      <Card>
        <EmptyState
          heading="Page not found"
          image=""
          action={{ content: 'Back home', onAction: () => navigate('/') }}
        >
          {/* The address is quoted back deliberately. A 404 that does not
              say what it could not find leaves the reader unable to tell
              a typo from a broken link. */}
          <p>{`We couldn't find ${location.pathname}.`}</p>
        </EmptyState>
      </Card>
    </Page>
  );
}
