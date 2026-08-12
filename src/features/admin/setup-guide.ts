import type { ChurchSettings } from '../../core/church-settings';

export interface SetupStep {
  id: string;
  title: string;
  description: string;
  /** Where the admin goes to do it. Bare sub-path. */
  path: string;
  done: boolean;
}

/**
 * Shopify's setup guide, for a church.
 *
 * The steps are **measured, not remembered** — each one asks the
 * church's own settings whether it has been done. Nothing is stored, so
 * there is no state to go stale, and a church that clears a field sees
 * the step reopen rather than keeping a tick it no longer earns.
 *
 * The Flutter build had a checklist too, and it stored booleans.
 */
export function setupSteps(settings: ChurchSettings): SetupStep[] {
  return [
    {
      id: 'name',
      title: 'Name your church',
      description: 'Shown in the top bar, on every page of your website, and on every link you share.',
      path: '/admin/settings',
      done: settings.churchName !== '' && settings.churchName !== 'Your Church',
    },
    {
      id: 'service-times',
      title: 'Add your service times',
      description: 'The one thing a first-time visitor comes to your website to find out.',
      path: '/admin/settings',
      done: settings.serviceTimes.length > 0,
    },
    {
      id: 'address',
      title: 'Add your address',
      description: 'Puts you on the map on Plan a Visit, and in the footer of every page.',
      path: '/admin/settings',
      done: settings.contact.address !== '',
    },
    {
      id: 'contact',
      title: 'Add a way to reach you',
      description: 'A phone number or an email address, so somebody with a question can ask it.',
      path: '/admin/settings',
      done: settings.contact.email !== '' || settings.contact.phone !== '',
    },
    {
      id: 'brand',
      title: 'Set your colours',
      description: 'Your website takes its palette from here. The admin stays as it is.',
      path: '/admin/website/themes',
      done: settings.logoUrl !== '',
    },
    {
      id: 'giving',
      title: 'Turn on giving',
      description: 'Take one-off and recurring gifts, and track them against funds.',
      path: '/admin/giving',
      done: settings.features.giving && settings.social.givingUrl !== '',
    },
  ];
}

export function setupProgress(steps: SetupStep[]): { done: number; total: number } {
  return { done: steps.filter((s) => s.done).length, total: steps.length };
}
