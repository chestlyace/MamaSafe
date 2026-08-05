export default function HeartbeatLine({ className = '' }) {
  return (
    <svg
      viewBox="0 0 600 160"
      className={`heartbeat ${className}`}
      fill="none"
      aria-hidden="true"
      preserveAspectRatio="none"
    >
      <path
        className="heartbeat-path"
        d="M0 80 H120 L145 80 160 45 175 115 190 80 H230 L250 80 262 60 274 100 286 80 H360 L375 80 390 30 408 130 424 80 H600"
        stroke="currentColor"
        strokeWidth="3"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
