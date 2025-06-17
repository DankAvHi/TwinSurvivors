using System;
using Godot;

public partial class Enemy : CharacterBody2D
{
    public float Speed = 100.0f;

    [Export]
    public NodePath PlayerNodePath { get; set; }
    private CharacterBody2D player;
    private AnimatedSprite2D animatedSprite;

    public override void _Ready()
    {
        animatedSprite = GetNode<AnimatedSprite2D>("AnimatedSprite2D");
        animatedSprite.Play("default");
        player = GetNode<CharacterBody2D>(PlayerNodePath);
    }

    public override void _Process(double delta)
    {
        if (player != null && IsInstanceValid(player))
        {
            Vector2 directionToPlayer = (player.GlobalPosition - GlobalPosition).Normalized();
            Velocity = directionToPlayer * Speed;
        }
        else
        {
            Velocity = Vector2.Zero;
        }
        MoveAndSlide();
    }
}
