import { Inter } from "next/font/google";
import "./globals.css";
import { Providers } from "./Providers";

const inter = Inter({ subsets: ["latin"] });

export const metadata = {
  title: "TripShip Admin",
  description: "TripShip Admin Dashboard",
};

const themeScript = `
(function() {
  try {
    var t = localStorage.getItem('tripship_admin_theme');
    var themes = ['midnight','dark','dim','light','bright','crimson','forest','ocean','amber','violet'];
    if (t && themes.indexOf(t) >= 0) document.documentElement.setAttribute('data-theme', t);
    else document.documentElement.setAttribute('data-theme', 'light');

    var s = localStorage.getItem('tripship_admin_font_size');
    var sizes = ['small','normal','large','xl','xxl'];
    if (s && sizes.indexOf(s) >= 0) document.documentElement.setAttribute('data-font-size', s);
    else document.documentElement.setAttribute('data-font-size', 'normal');
  } catch (e) { /* localStorage unavailable */ }
})();
`;

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
        <script dangerouslySetInnerHTML={{ __html: themeScript }} />
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
