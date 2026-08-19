// k6 load: launch is boring. 500 concurrent VUs for 10 minutes against
// PRODUCTION STATIC PATHS ONLY; form endpoints are excluded from load by
// law (they write durable rows; a load test is not a lead).
// Run (cutover day):  k6 run -e BASE=https://keepstate.ai infra/load-test.js
// Rehearsal (small):  k6 run -e BASE=<staging> -e VUS=50 -e DUR=2m infra/load-test.js
import http from 'k6/http';
import { check } from 'k6';

const BASE = __ENV.BASE;
const PATHS = ['/', '/pricing/', '/proof/', '/docs/', '/docs/quickstart/', '/manifesto/'];

export const options = {
  vus: Number(__ENV.VUS ?? 500),
  duration: __ENV.DUR ?? '10m',
  thresholds: {
    http_req_failed: ['rate==0'],
    'http_req_waiting{expected_response:true}': ['p(95)<300'],
  },
};

export default function () {
  const path = PATHS[Math.floor(Math.random() * PATHS.length)];
  const res = http.get(`${BASE}${path}`);
  check(res, { 'status 200': (r) => r.status === 200 });
}
