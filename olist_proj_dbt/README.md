### Before running dbt

This project's Azure SQL database is on a free/serverless tier that auto-pauses
after inactivity and can take 30-60s to resume. dbt's own connection retries
don't wait long enough to bridge a cold start, so wake the database first:

```
uv run python ../check_connection.py
```

Run that from the repo root once, then dbt commands below will connect normally.

### Using the starter project

Try running the following commands:
- dbt run
- dbt test


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
