import { useState, useEffect } from "react";

export const useResize = (myRef: any) => {
  const [width, setWidth] = useState(0);
  const [height, setHeight] = useState(0);

  const handleResize = () => {
    setWidth(myRef.current.offsetWidth);
    setHeight(myRef.current.offsetHeight);
  };

  useEffect(() => {
    setWidth(myRef.current.clientWidth);
    setHeight(myRef.current.clientHeight);
  }, []);

  useEffect(() => {
    myRef.current && window.addEventListener("resize", handleResize);
    return () => {
      window.removeEventListener("resize", handleResize);
    };
  }, [myRef.current]);

  return { width, height };
};
