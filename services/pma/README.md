# Generate htpassword for http basic auth

- Generate

```shell
docker run --rm httpd:2.4-alpine htpasswd -nbB pma_user password-length-8
```

- Result

```shell
pma_user:$2y$05$hoC5xYfnFpvAVn3pvGPKeuCfuLQaRUnnBRwKz.vgy1lhF2MdUThim
```

- Add extra $ to make it work

```shell
pma_user:$$2y$$05$$hoC5xYfnFpvAVn3pvGPKeuCfuLQaRUnnBRwKz.vgy1lhF2MdUThim
```

## Edit and insert in compose yml

```shell
nano docker-compose.yaml

- "traefik.http.middlewares.pma-auth.basicauth.users=pma_user:generated_password"
```
