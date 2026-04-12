'use client';
import { AntdRegistry } from '@ant-design/nextjs-registry';
import '@ant-design/v5-patch-for-react-19';
import { ConfigProvider } from 'antd';
import React from 'react';

const AntdesignProvider = ({ children }: React.PropsWithChildren) => {
  return (
    <AntdRegistry>
      <ConfigProvider
        theme={{
          cssVar: true,
          token: {
            fontFamily: 'var(--font-geist-sans)',
            colorPrimary: 'var(--color-primary-500)',
            lineHeight: 1,
            borderRadius: 8,
            fontSize: 16,
            colorBgContainer: '#ffffff',
            colorBgContainerDisabled: 'var(--color-app-gray-100)',
            controlHeight: 40,
            controlHeightLG: 48,
            controlHeightSM: 32,
            colorBorder: 'var(--color-app-gray-300)',
            colorLink: 'var(--color-primary-500)',
            colorText: 'var(--color-app-gray-900)',
            colorTextDisabled: 'var(--color-app-gray-400)',
            colorTextDescription: 'var(--color-app-gray-500)',
            colorBorderSecondary: 'var(--color-app-gray-200)',
            colorBgTextHover: 'var(--color-primary-100)',
            colorTextPlaceholder: 'var(--color-app-gray-500)',
          },
          components: {
            Button: {
              colorPrimary: 'var(--color-primary-500)',
              colorPrimaryHover: 'var(--color-primary-600)',
              colorPrimaryActive: 'var(--color-primary-600)',
              primaryShadow: 'var(--shadow-app-xs)',
              defaultShadow: 'var(--shadow-app-xs)',
              defaultActiveBg: 'var(--color-primary-50)',
              defaultActiveBorderColor: 'var(--color-primary-500)',
              fontWeight: 600,
              contentFontSize: 16,
            },
            Input: {
              activeBorderColor: 'var(--color-primary-500)',
              activeShadow: 'var(--shadow-app-ring-xs)',
              hoverBorderColor: 'var(--color-primary-500)',
              inputFontSize: 16,
              paddingBlock: 8,
              paddingInline: 12,
              colorTextPlaceholder: 'var(--color-app-gray-500)',
              lineHeight: 1,
            },
            Select: {
              activeBorderColor: 'var(--color-primary-500)',
              hoverBorderColor: 'var(--color-primary-500)',
              optionActiveBg: 'var(--color-primary-50)',
              optionSelectedBg: 'var(--color-primary-50)',
              optionSelectedColor: 'var(--color-primary-500)',
              optionSelectedFontWeight: 600,
              optionFontSize: 16,
              optionHeight: 40,
            },
            Table: {
              borderColor: 'var(--color-app-gray-200)',
              headerBg: '#ffffff',
              headerBorderRadius: 10,
              headerColor: 'var(--color-app-gray-700)',
              rowHoverBg: 'var(--color-app-gray-50)',
            },
            Modal: {
              contentBg: '#ffffff',
              headerBg: '#ffffff',
              titleColor: 'var(--color-app-gray-900)',
              titleFontSize: 18,
              borderRadiusLG: 12,
              paddingLG: 24,
            },
            Card: {
              colorBgContainer: '#ffffff',
              colorBorderSecondary: 'var(--color-app-gray-200)',
              borderRadiusLG: 12,
              boxShadowTertiary: 'var(--shadow-app-sm)',
              headerBg: 'transparent',
              paddingLG: 24,
            },
            Form: {
              labelColor: 'var(--color-app-gray-950)',
            },
            Tabs: {
              inkBarColor: 'var(--color-primary-500)',
              itemActiveColor: 'var(--color-primary-500)',
              itemColor: 'var(--color-app-gray-500)',
              itemHoverColor: 'var(--color-primary-500)',
              itemSelectedColor: 'var(--color-primary-500)',
            },
            Menu: {
              itemBg: 'var(--color-primary-50)',
              itemColor: 'var(--color-app-gray-900)',
              itemHoverBg: 'var(--color-primary-100)',
              itemSelectedBg: 'var(--color-primary-500)',
              itemSelectedColor: '#ffffff',
              itemBorderRadius: 8,
              itemHeight: 40,
              itemMarginBlock: 4,
              itemMarginInline: 4,
            },
          },
        }}
      >
        {children}
      </ConfigProvider>
    </AntdRegistry>
  );
};

export default AntdesignProvider;
