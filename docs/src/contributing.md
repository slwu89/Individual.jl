# [Contributing](@id ref_contributing)

Thank you for taking the time to contribute to individual.jl!

## Issues

If you find a bug, have a question about how to use a feature that does not have sufficient documentation, or have a suggestion for improvement, please leave an issue at our GitHub repo.

For bug reports please include:

 * individual.jl version
 * Operating System
 * Julia version
 * Steps to recreate
 * Expected behaviour
 * Actual behaviour

## Git

We use Git on this project. Which means we use `main`, `dev`, `feat/*`, `bug/*`, and `hotfix/*` branches. Please refer to [this post](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) for more information of each type of branch. 

  * `main`: this branch always stores the last release of the software, and is a protected branch. A pull request should
  not be submitted to `main` unless it is from `dev`, meaning that the software version should be updated.
  * `dev`: all pull requests from users should be made to the `dev` branch. This branch is protected from deletion.
  * `feat`: new and significantly enhanced features are made in `feat` branches before being merged with `dev`. After a `feat/*` branch is merged with `dev`, it can be deleted.
  * `bug`: these branches fix bugs, usually after being raised as an issue. After a `bug/*` branch is merged with `dev`, it can be deleted.
  * `hotfix`: the difference between a `bug/*` and `hotfix/*` branch is `hotfix` is for small quick fixes (misspellings, incorrect arguments, etc), and can be directly merged into `main`. After they are merged, it can be deleted.

We periodically merge `dev` into `main` for release updates.

## Continuous integration

We use GitHub Actions as our continuous integration platform to run workflows. We run several types of workflows:

- Test checks run during any pull request to `[main, dev]` branches.
- Documentation building only runs on pushes to `main`, which will occur when `dev` is merged with `main`.

Please note that sometimes hard to diagnose bugs can be due to out of date
workflows. If you find a strange or unusual bug coming from a workflow, this
is something to consider checking.

## Pull requests

If making a pull request, please only use `dev` as the base branch. If you are adding a new feature (i.e. the pull is from a `feat/*` branch),
please ensure you have added minimal tests using testthat so that the functionality of your feature can be tested.