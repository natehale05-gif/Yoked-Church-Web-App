import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';

import '@shopify/polaris/build/esm/styles.css';
import './styles/app.css';

import { App } from './app/App';

const container = document.getElementById('root');
if (!container) throw new Error('index.html is missing #root');

createRoot(container).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
