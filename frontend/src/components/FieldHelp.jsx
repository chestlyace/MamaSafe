export default function FieldHelp({ text }) {
  if (!text) return null;

  return (
    <span className="group relative inline-flex ml-1.5 align-middle cursor-help">
      <span className="material-symbols-outlined text-[16px] text-text-muted">info</span>
      <span className="pointer-events-none absolute left-1/2 bottom-full z-50 mb-2 w-max max-w-[260px] -translate-x-1/2 whitespace-normal rounded-lg bg-gray-900 px-3 py-2 text-left text-xs leading-snug text-white opacity-0 shadow-lg transition-opacity duration-150 group-hover:opacity-100">
        {text}
      </span>
    </span>
  );
}
