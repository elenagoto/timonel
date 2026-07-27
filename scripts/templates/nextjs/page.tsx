export default function Home() {
  return (
    <main style={{ padding: '2rem', fontFamily: 'system-ui' }}>
      <h1>🎯 $APP_NAME</h1>
      <p>Running in Dockerator!</p>
      <p>
        Access via:{' '}
        <a href='http://$SAFE_NAME.localhost'>$SAFE_NAME.localhost</a>
      </p>
    </main>
  );
}
