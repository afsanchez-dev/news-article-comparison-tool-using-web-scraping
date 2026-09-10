/**
 * A function for parsing ISO dates to locale date format
 * @param {string} dateTime
 * @returns {string}
 */
export function parseDateTime(dateTime: string): string {
    return new Date(dateTime).toLocaleString('es')
}
