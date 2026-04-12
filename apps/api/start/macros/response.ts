import { Response } from '@adonisjs/core/http';

/**
 * Extends the AdonisJS Response object with a `sendFormatted` macro.
 * This macro standardizes API responses by wrapping the data in an object
 * containing `status`, an optional `data`, and an optional `message`.
 *
 * @param {T} data - The actual data payload to be sent in the response.
 * If `message` is not provided and `data` is a string, `data` will be treated as the message.
 * Otherwise, `data` will be included if it's truthy (not `false`, `0`, `null`, `undefined`, or `''`).
 * @param {string} [message] - An optional message to accompany the response,
 * useful for success or error descriptions.
 * @returns {void}
 */
Response.macro('sendFormatted', function sendFormatted<
  T,
>(this: Response, data: T, message?: string) {
  const code = this.response.statusCode;
  const formattedData: {
    status: number;
    data?: T;
    message?: string;
  } = {
    status: code,
  };

  // Case: Both data and message are provided
  if (data !== undefined && message !== undefined) {
    formattedData.message = message;
    formattedData.data = data;
    this.send(formattedData);
  }

  // Case: Only data is provided
  if (data !== undefined) {
    if (typeof data === 'string') {
      // Treat as message if data is a string
      formattedData.message = data;
    } else {
      // Treat as actual data if it's not a string
      formattedData.data = data;
    }
  }

  this.send(formattedData);
});

declare module '@adonisjs/core/http' {
  interface Response {
    /**
     * Sends a formatted API response with status, an optional data payload, and an optional message.
     * If `message` is not provided and `data` is a string, `data` will be treated as the message.
     * Otherwise, the data payload will only be included.
     * @param data The data payload.
     * @param message An optional message.
     */
    sendFormatted<T>(data: T, message?: string): void;
  }
}

Response.macro('sendResult', function sendResult<T>(this: Response, data: T, message?: string) {
  return this.send({
    status: this.response.statusCode,
    result: data,
    message,
  });
});

declare module '@adonisjs/core/http' {
  interface Response {
    sendResult<T>(data: T, message?: string): void;
  }
}

interface ErrorObject {
  message: string;
  field?: string;
}

Response.macro(
  'sendError',
  function sendError(this: Response, errors: string | ErrorObject | ErrorObject[]) {
    if (typeof errors === 'string') {
      errors = [{ message: errors }];
    } else if (!Array.isArray(errors)) {
      errors = [errors];
    }
    return this.send({
      status: this.response.statusCode,
      errors,
    });
  }
);

declare module '@adonisjs/core/http' {
  interface Response {
    /**
     * Sends an error response to the client.
     *
     * @param errors - The error(s) to send. Can be a string, a single `ErrorObject`, or an array of `ErrorObject`.
     */
    sendError(errors: string | ErrorObject | ErrorObject[]): void;
  }
}
