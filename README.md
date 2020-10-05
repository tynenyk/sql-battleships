# Требования
<li>postgresql 12.4</li>
<li>docker (optional)</li>

# Запуск сервера в докере
```
docker build -t sql-battleships .
docker run -p 5432:5432 sql-battleships
```

# Запуск игры
```
psql -U postgres <<<'call screen_loop()' & psql -U postgres
```
