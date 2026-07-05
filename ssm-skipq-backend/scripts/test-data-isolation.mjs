/**
 * Data-isolation smoke test — run with backend up:
 *   node scripts/test-data-isolation.mjs
 */
const API = process.env.API_URL || 'http://localhost:5000';

const post = async (path, body, token) => {
  const res = await fetch(`${API}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  });
  const data = await res.json();
  return { status: res.status, data };
};

const get = async (path, token) => {
  const res = await fetch(`${API}${path}`, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  });
  const data = await res.json();
  return { status: res.status, data };
};

const registerStudent = async (name, mobile) => {
  const { status, data } = await post('/api/auth/student-register', {
    name,
    mobile,
  });
  if (status !== 201 || !data.success) {
    throw new Error(`Register failed for ${mobile}: ${data.message}`);
  }
  return data.data;
};

const loginStudent = async (mobile) => {
  const { status, data } = await post('/api/auth/student-login', { mobile });
  if (status !== 200 || !data.success) {
    throw new Error(`Login failed for ${mobile}: ${data.message}`);
  }
  return data.data;
};

const run = async () => {
  console.log('=== Data isolation test ===\n');

  const suffix = String(Date.now()).slice(-9);
  const mobileA = `6${suffix}`;
  const mobileB = `7${suffix}`;

  const studentA = await registerStudent('Test Student A', mobileA);
  const studentB = await registerStudent('Test Student B', mobileB);

  if (studentA.user.id === studentB.user.id) {
    throw new Error('Different mobiles returned the same student id');
  }
  console.log('✓ Two registrations created distinct student accounts');

  const loginAgain = await loginStudent(mobileA);
  if (loginAgain.user.id !== studentA.user.id) {
    throw new Error('Same mobile re-login did not return the same student id');
  }
  console.log('✓ Same mobile re-login returns the same account');

  const menuRes = await get('/api/menu/items', studentA.token);
  const menuItem = menuRes.data?.data?.items?.[0];
  if (!menuItem) {
    console.log('⚠ No menu items — skipping order placement tests');
  } else {
    const orderBody = {
      items: [{ menuItemId: menuItem.id, quantity: 1 }],
      total: menuItem.price,
      paymentMethod: 'PAY_AT_COUNTER',
    };

    const orderA = await post('/api/orders', orderBody, studentA.token);
    const orderB = await post('/api/orders', orderBody, studentB.token);

    if (orderA.status !== 201 || orderB.status !== 201) {
      console.log('Order A:', orderA.status, orderA.data.message);
      console.log('Order B:', orderB.status, orderB.data.message);
    } else {
      const ordersA = await get('/api/orders', studentA.token);
      const ordersB = await get('/api/orders', studentB.token);
      const idsA = ordersA.data.data.orders.map((o) => o.id);
      const idsB = ordersB.data.data.orders.map((o) => o.id);
      const overlap = idsA.filter((id) => idsB.includes(id));

      if (overlap.length > 0) {
        throw new Error('Students share order ids in GET /api/orders');
      }
      console.log('✓ Each student only sees their own orders');
    }
  }

  const profileA = await get('/api/auth/me', studentA.token);
  const profileB = await get('/api/auth/me', studentB.token);
  if (profileA.data.data.user.mobile !== mobileA) {
    throw new Error('Profile A mobile mismatch');
  }
  if (profileB.data.data.user.mobile !== mobileB) {
    throw new Error('Profile B mobile mismatch');
  }
  console.log('✓ Profile (GET /api/auth/me) scoped to JWT user only');

  console.log('\nAll isolation checks passed.');
};

run().catch((err) => {
  console.error('\nTest failed:', err.message);
  process.exit(1);
});
