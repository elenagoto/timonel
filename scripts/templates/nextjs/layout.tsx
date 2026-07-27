import type { ReactNode } from 'react';

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang='en'>
      <body>
        {children}

        <footer style={{ padding: '2rem', fontFamily: 'system-ui' }}>
          This is the footer for 🎯 $APP_NAME
        </footer>
      </body>
    </html>
  );
}
