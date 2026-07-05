/**
 * End-to-end API flow test — run with backend up:
 *   node scripts/test-e2e-flow.mjs
 */
const API = process.env.API_URL || 'http://localhost:5000';

const req = async (method, path, body, token) => {
  const res = await fetch(`${API}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const data = await res.json().catch(() => ({}));
  return { status: res.status, data };
};

const step = (label, ok, detail = '') => {
  console.log(`${ok ? '✓' : '✗'} ${label}${detail ? ` — ${detail}` : ''}`);
  if (!ok) throw new Error(label);
};

const run = async () => {
  console.log('=== E2E flow test (API) ===\n');

  const window = await req('GET', '/api/settings/ordering-window');
  step('Ordering window endpoint', window.status === 200);
  console.log(`  Window open: ${window.data?.data?.isOpen}\n`);

  const e2eMobile = `8${String(Date.now()).slice(-9)}`;

  let studentLogin = await req('POST', '/api/auth/student-register', {
    name: 'E2E Student',
    mobile: e2eMobile,
  });
  if (studentLogin.status === 409) {
    studentLogin = await req('POST', '/api/auth/student-login', {
      mobile: e2eMobile,
    });
  }
  step(
    'Student auth',
    (studentLogin.status === 201 || studentLogin.status === 200) &&
      studentLogin.data.success,
  );
  const studentToken = studentLogin.data.data.token;
  const studentId = studentLogin.data.data.user.id;

  const managerLogin = await req('POST', '/api/auth/manager-login', {
    managerId: 'SSM001',
    password: 'manager123',
  });
  step('Manager login', managerLogin.status === 200 && managerLogin.data.success);
  const managerToken = managerLogin.data.data.token;

  const menu = await req('GET', '/api/menu/items', null, studentToken);
  step('Browse menu', menu.status === 200);
  const item = menu.data?.data?.items?.find((i) => i.available);
  step('Menu has available item', !!item, item?.name);

  const orderRes = await req(
    'POST',
    '/api/orders',
    {
      items: [{ menuItemId: item.id, quantity: 1 }],
      total: item.price,
      paymentMethod: 'PAY_AT_COUNTER',
    },
    studentToken,
  );

  if (orderRes.status === 403 && orderRes.data.message?.includes('closed')) {
    console.log('⚠ Ordering window closed — order blocked server-side (expected)');
    return;
  }

  step('Place order (Pay at Counter)', orderRes.status === 201, orderRes.data.message);
  const orderId = orderRes.data.data.order.id;
  const tokenNumber = orderRes.data.data.order.tokenNumber;
  console.log(`  Token: ${tokenNumber}`);

  const managerOrders = await req('GET', '/api/orders/manager', null, managerToken);
  step(
    'Manager sees order',
    managerOrders.data.data.orders.some((o) => o.id === orderId),
  );

  const statuses = ['CONFIRMED', 'PREPARING', 'READY', 'PICKED_UP'];
  for (const expected of statuses) {
    const adv = await req('PATCH', `/api/orders/${orderId}/status`, null, managerToken);
    step(`Advance to ${expected}`, adv.status === 200 && adv.data.data.order.status === expected);
  }

  const pay = await req(
    'PATCH',
    `/api/orders/${orderId}/payment`,
    { paymentStatus: 'PAID' },
    managerToken,
  );
  step('Mark payment received', pay.status === 200);

  const feedback = await req(
    'POST',
    `/api/orders/${orderId}/feedback`,
    { rating: 5, review: 'Great food!' },
    studentToken,
  );
  step('Student feedback', feedback.status === 201);

  const relogin = await req('POST', '/api/auth/student-login', {
    mobile: e2eMobile,
  });
  step(
    'Re-login same mobile',
    relogin.status === 200 && relogin.data.data.user.id === studentId,
  );

  const history = await req('GET', '/api/orders', null, relogin.data.data.token);
  step(
    'Order in history after re-login',
    history.data.data.orders.some((o) => o.id === orderId),
  );

  console.log('\nAll E2E steps passed.');
};

run().catch((err) => {
  console.error('\nE2E failed:', err.message);
  process.exit(1);
});
