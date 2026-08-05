import React from "react";
import { render } from "@testing-library/react-native";
import { I18nextProvider } from "react-i18next";
import i18next from "i18next";

jest.mock("react-native", () => {
  const React = require("react");
  const component = (name: string) => {
    const C = ({ children, ...props }: any) =>
      React.createElement(name, props, children);
    C.displayName = name;
    return C;
  };
  return {
    __esModule: true,
    default: { View: component("View"), Text: component("Text") },
    View: component("View"),
    Text: component("Text"),
    Platform: { OS: "ios", select: (obj: any) => obj.ios || obj.default },
    StyleSheet: {
      create: (s: any) => s,
      flatten: (style: any) => {
        if (Array.isArray(style)) {
          return Object.assign({}, ...style.filter(Boolean));
        }
        return style || {};
      },
    },
  };
});

import RiskBadge from "../../components/RiskBadge";

const i18n = i18next.createInstance();
i18n.init({
  lng: "en",
  fallbackLng: "en",
  resources: {
    en: {
      translation: {
        high_risk: "High Risk",
        moderate_risk: "Mid Risk",
        low_risk: "Low Risk",
      },
    },
  },
  interpolation: { escapeValue: false },
});

const renderWithI18n = (component: React.ReactElement) =>
  render(<I18nextProvider i18n={i18n}>{component}</I18nextProvider>);

describe("RiskBadge", () => {
  it("renders high risk", () => {
    const { getByText } = renderWithI18n(<RiskBadge level="high risk" />);
    expect(getByText("High Risk")).toBeTruthy();
  });

  it("renders mid risk", () => {
    const { getByText } = renderWithI18n(<RiskBadge level="mid risk" />);
    expect(getByText("Mid Risk")).toBeTruthy();
  });

  it("renders low risk", () => {
    const { getByText } = renderWithI18n(<RiskBadge level="low risk" />);
    expect(getByText("Low Risk")).toBeTruthy();
  });

  it("renders default for unknown", () => {
    const { getByText } = renderWithI18n(<RiskBadge level="unknown" />);
    expect(getByText("Low Risk")).toBeTruthy();
  });
});
