import { useEffect, useRef, useState } from "react";

// Tracks a form value that auto-fills from a `computed` source until the user
// manually edits it (then it "sticks"). A revert action restores the computed
// value and re-enables auto-fill. Returns:
//   handleChange(next)  – call from the field's onChange
//   showRevert         – whether the revert link should render
//   revert()           – restore the computed value
export default function useComputedValue(value, computed, onChange) {
  const dirtyRef = useRef(false);
  const lastComputed = useRef(computed);
  const [showRevert, setShowRevert] = useState(false);

  useEffect(() => {
    if (dirtyRef.current) return;
    if (computed !== null && computed !== undefined && computed !== value) {
      onChange(computed);
    } else if (
      lastComputed.current !== null &&
      lastComputed.current !== undefined &&
      (computed === null || computed === undefined) &&
      value !== "" &&
      value !== null &&
      value !== undefined
    ) {
      onChange("");
    }
    lastComputed.current = computed;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [computed]);

  const handleChange = (next) => {
    onChange(next);
    if (next === computed) {
      dirtyRef.current = false;
      setShowRevert(false);
    } else {
      dirtyRef.current = true;
      setShowRevert(true);
    }
  };

  const revert = () => {
    dirtyRef.current = false;
    setShowRevert(false);
    if (computed !== null && computed !== undefined) onChange(computed);
  };

  return { handleChange, showRevert: showRevert && computed !== null && computed !== undefined && value !== computed, revert };
}
