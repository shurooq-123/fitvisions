function addMonths(date, months) {
  if (!Number.isInteger(months) || months < 1 || months > 120) throw new Error('Invalid duration');
  const result = new Date(date);
  const day = result.getUTCDate(); result.setUTCDate(1);
  result.setUTCMonth(result.getUTCMonth() + months);
  const last = new Date(Date.UTC(result.getUTCFullYear(), result.getUTCMonth()+1,0)).getUTCDate();
  result.setUTCDate(Math.min(day,last)); return result;
}
function duration(record) {
  if (Number.isInteger(record.durationMonths) && record.durationMonths > 0 && record.durationMonths <= 120) return record.durationMonths;
  const match = /^(\d+)\s*months?$/i.exec(record.duration || '');
  if (match && +match[1] > 0 && +match[1] <= 120) return +match[1];
  return (record.price ?? record.amount) === 7 ? 6 : (record.price ?? record.amount) === 3 ? 1 : 0;
}
function endOf(record) {
  if (record.expiresAt?.toDate) return record.expiresAt.toDate();
  if (!record.createdAt?.toDate || !duration(record)) return null;
  return addMonths(record.createdAt.toDate(),duration(record));
}
function active(record, now = new Date()) {
  const end = endOf(record); const start = (record.startsAt ?? record.createdAt)?.toDate?.();
  return ['pending','demo_active','paid'].includes(record.status) && end && start && start <= now && end > now;
}
module.exports={addMonths,duration,endOf,active};
