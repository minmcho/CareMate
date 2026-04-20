/**
 * Client-side circuit breaker.
 *
 * Mirrors the backend Hystrix-style breaker used to stop hammering upstream
 * AI services when they're failing. Includes a half-open probe window.
 */

import type { CircuitBreakerState } from "./types";

const OPEN_DURATION_MS = 20_000;
const THRESHOLD = 5;

export class CircuitBreaker {
  private state: CircuitBreakerState = {
    status: "closed",
    failures: 0,
    openedAtMs: 0,
  };

  get snapshot(): CircuitBreakerState {
    return { ...this.state };
  }

  allow(): boolean {
    if (this.state.status === "open") {
      if (Date.now() - this.state.openedAtMs > OPEN_DURATION_MS) {
        this.state.status = "half-open";
        return true;
      }
      return false;
    }
    return true;
  }

  recordSuccess(): void {
    this.state.status = "closed";
    this.state.failures = 0;
    this.state.openedAtMs = 0;
  }

  recordFailure(): void {
    this.state.failures += 1;
    if (this.state.failures >= THRESHOLD || this.state.status === "half-open") {
      this.state.status = "open";
      this.state.openedAtMs = Date.now();
    }
  }
}
