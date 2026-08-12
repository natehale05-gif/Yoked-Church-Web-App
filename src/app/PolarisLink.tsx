import { Link } from 'react-router-dom';
import type { LinkLikeComponent } from '@shopify/polaris/build/ts/src/utilities/link';

/**
 * Teaches Polaris to navigate with the router instead of the browser.
 *
 * Without this every `url` in a Polaris component — the whole sidebar,
 * every breadcrumb, every action — renders a plain `<a href>` and a
 * click reloads the page. Two things then break at once: the app boots
 * from scratch on every navigation, and the address goes to the raw
 * `url`, which is missing the router's basename. On GitHub Pages that
 * means `/c/yoked-demo/admin/giving` instead of
 * `/Yoked-Church-Web-App/c/yoked-demo/admin/giving`, so the first click
 * on Giving left the app entirely.
 *
 * Found by clicking it, not by a test: it type-checks, it builds, and
 * the sidebar renders perfectly either way.
 */
export const PolarisLink: LinkLikeComponent = ({ url, children, external, target, ...rest }) => {
  const leavesTheApp = external === true || /^(https?:|mailto:|tel:)/.test(url);

  if (leavesTheApp) {
    return (
      <a href={url} target={target ?? '_blank'} rel="noopener noreferrer" {...rest}>
        {children}
      </a>
    );
  }

  return (
    <Link to={url} target={target} {...rest}>
      {children}
    </Link>
  );
};
