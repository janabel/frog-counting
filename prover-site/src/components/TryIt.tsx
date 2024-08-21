export function TryIt({
  onClick,
  label
}: {
  onClick: () => void;
  label: string;
}) {
  return (
    <div className="flex items-center gap-2">
      <span className="text-md"></span>
      <button className="btn btn-primary" onClick={onClick}>
        {label}
      </button>
    </div>
  );
}
